class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, only: [ :show, :edit, :update, :destroy, :purchase_decision, :submit_decision ]
  before_action :ensure_ready_for_decision, only: [ :purchase_decision, :submit_decision ]
  before_action :prevent_access_after_decision, only: [ :purchase_decision, :submit_decision ]

  def index
    @items = current_user.items.order(created_at: :desc)

    if params[:status].present?
      @items = @items.where(status: params[:status])
    end
  end

  def show; end

  def new
    @item = Item.new
  end

  def create
    @item = current_user.items.build(item_params)
    choice = params[:cooldown_choice]

    if choice == "skip"
      @item.skip_cooldown!
    elsif choice.present? && Item.cooldown_durations.key?(choice)
      @item.cooldown_duration = choice
    end

    if @item.save
      if choice == "skip"
        # クールダウンスキップ時は購入判断画面に遷移
        redirect_to purchase_decision_item_path(@item), flash: { success: t("flash.items.create.success") }
      else
        # クールダウンタイマー使用時はアイテム詳細画面に遷移
        redirect_to item_path(@item), flash: { success: t("flash.items.create.success") }
      end
    else
      flash.now[:alert] = t("flash.items.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @item.update(item_params)
      redirect_to item_path(@item), success: t("flash.items.update.success")
    else
      flash.now[:alert] = t("flash.items.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @item.destroy!
    redirect_to items_path, success: t("flash.items.destroy.success")
  rescue ActiveRecord::RecordNotDestroyed
    redirect_to item_path(@item), alert: t("flash.items.destroy.failure")
  end

  # フォーム表示用
  def purchase_decision
    @journal = @item.latest_draft_journal || @item.journals.build
    @questions = Question.where(user_id: nil).order(:position)
    @answers_map = @item.answers.where(is_draft: true).index_by(&:question_id)

    # フォーム送信後(paramsがある場合)は params 優先で上書き
    if answers_params.present?
      answers_params.each do |question_id_str, answer_param|
        question_id = question_id_str.to_i
        choice = answer_param["choice"]
        next if choice.blank?

        @answers_map[question_id] = Answer.new(
          question_id: question_id,
          choice: choice
        )
      end
    end
  end

  # フォーム送信・保存用
  def submit_decision
    commit_type = params[:commit_type]

    case commit_type

    # 下書き保存
    when "draft"
      save_or_update_draft
      redirect_to item_path(@item), success: t("flash.items.decide.success.draft")

    # 購入判断完了
    when "complete"
      status_params = params.dig(:item, :status)

      if status_params.blank?
        # バリデーションエラー(購入判断完了時は「買う・買わない」の選択が必要)
        @item.errors.add(:status, t("flash.items.decide.validation.status_required"))

        @item.assign_attributes(item_params)

        @questions = Question.where(user_id: nil).order(:position)
        @answers_map = build_answers_from_params

        build_journal_from_params

        flash.now[:alert] = t("flash.items.decide.failure")
        render :purchase_decision, status: :unprocessable_entity
      else
        # バリデーションOK(購入判断「買う・買わない」を選択済み)
        if @item.update(status: status_params) # 登録成功
          finalize_journal
          finalize_answers
          redirect_to dashboards_path, success: t("flash.items.decide.success.complete")
        else # 登録失敗
          @item.assign_attributes(item_params)
          @answers_map = build_answers_from_params
          build_journal_from_params

          flash.now[:alert] = t("flash.items.decide.failure")
          render :purchase_decision, status: :unprocessable_entity
        end
      end
    end
  end

  private

  # 下書き保存
  def save_or_update_draft
    save_item_draft_fields
    save_answers_draft
    save_journal_draft
  end

  def save_item_draft_fields
    draft_attributes = {}
    draft_attributes[:desire_level] = params.dig(:item, :desire_level) if params.dig(:item, :desire_level).present?
    draft_attributes[:current_mood] = params.dig(:item, :current_mood) if params.dig(:item, :current_mood).present?

    return if draft_attributes.empty?

    @item.update!(draft_attributes)
  end

  def save_answers_draft
    return if answers_params.blank?

    answers_params.each do |_, answer_param|
      next if answer_param[:choice].blank?

      question_id = answer_param["question_id"]
      answer = @item.answers.find_or_initialize_by(question_id: question_id)

      answer.choice = answer_param[:choice]
      answer.is_draft = true
      answer.save!
    end
  end

  def save_journal_draft
    return if journal_content.blank?

    draft_journal = @item.latest_draft_journal

    if draft_journal.present?
      # 下書きがある場合は更新
      draft_journal.update!(content: journal_content)
    else
      # 下書きが無い場合は新規作成
      @item.journals.create!(
        content: journal_content,
        is_draft: true
      )
    end
  end

  # 購入判断完了ボタンをクリック後、失敗(バリデーションエラーまたは登録失敗)
  def build_answers_from_params
    return {} if answers_params.blank?

    answers_map = {}

    answers_params.each do |question_id_str, answer_param|
      question_id = question_id_str.to_i
      choice = answer_param["choice"]
      next if choice.blank?

      answers_map[question_id] = Answer.new(
        question_id: question_id,
        choice: choice
      )
    end

    answers_map
  end

  def build_journal_from_params
    @journal = Journal.new(
      content: journal_content
    )
  end

  # 購入判断完了ボタンをクリック後、バリデーションOK
  def finalize_answers
    @item.answers.update_all(is_draft: false)
  end

  def finalize_journal
    return if journal_content.blank?

    draft_journal = @item.latest_draft_journal

    if draft_journal.present?
      # 下書きがある場合は更新
      draft_journal.update!(
        content: journal_content,
        is_draft: false
      )
      # 古い下書きを削除
      @item.journals.where(is_draft: true).where.not(id: draft_journal.id).destroy_all
    else

      # 下書きが無い場合は新規作成
      draft_journal = @item.journals.create!(
        content: journal_content,
        is_draft: false
      )
    end
  end

  def set_item
    @item = current_user.items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: t("flash.items.not_found")
  end

  # クールダウン完了前は、購入判断画面に遷移できない
  def ensure_ready_for_decision
    return if @item.ready_for_decision?

    redirect_to item_path(@item), alert: t("flash.items.decide.access_denied.cooldown_active")
  end

  # 購入判断完了後は、購入判断画面に遷移できない
  def prevent_access_after_decision
    return unless @item.decided?

    redirect_to item_path(@item), alert: t("flash.items.decide.access_denied.after_decision")
  end

  def item_params
    # permit : 必須チェック(無いとエラー)
    params.require(:item).permit(
      :name, :note, :cooldown_duration, :status, :desire_level, :current_mood
    )
  end

  def answers_params
    #  fetch : 無くてもデフォルト値{}を返すのでエラーにならない
    params.fetch(:answers, {}).transform_values do |answer|
      answer.permit(:choice, :question_id)
    end
  end

  def journal_content
    # dig : 無くてもnilを返すのでエラーにならない(ネストを安全に取得)
    params.dig(:item, :journal_content)
  end
end
