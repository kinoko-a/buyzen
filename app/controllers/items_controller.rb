class ItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_item, except: [ :index, :new, :create ]
  before_action :prevent_access_after_decision, only: [ :cooldown, :set_cooldown, :purchase_decision, :submit_decision ]
  before_action :ensure_cooldown_not_set, only: [ :cooldown, :set_cooldown ]
  before_action :ensure_ready_for_decision, only: [ :purchase_decision, :submit_decision ]

  def index
    @items = current_user.items.with_status(params[:status]).order(created_at: :desc).page(params[:page])
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

    begin
      @item.save!

      if choice == "skip"
        # クールダウンスキップ時は購入判断画面に遷移
        redirect_to purchase_decision_item_path(@item), flash: { success: t("flash.items.create.success") }
      else
        # クールダウンタイマー使用時はアイテム詳細画面に遷移
        redirect_to item_path(@item), flash: { success: t("flash.items.create.success") }
      end

    rescue ActiveRecord::RecordInvalid
      render :new, status: :unprocessable_entity

    rescue => e
      Rails.logger.error(e)
      flash.now[:alert] = t("flash.items.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    begin
      @item.update!(item_params)
      redirect_to item_path(@item), success: t("flash.items.update.success")

    rescue ActiveRecord::RecordInvalid
      render :edit, status: :unprocessable_entity

    rescue => e
      Rails.logger.error(e)
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

  # クールダウンタイマー（スキップ時）
  # 表示
  def cooldown
  end

  # 登録
  def set_cooldown
    choice = params[:cooldown_choice]

    unless choice.present?
      @item.errors.add(:cooldown_duration, "を選択してください")
      return render :cooldown, status: :unprocessable_entity
    end

    if Item.cooldown_durations.key?(choice)
      @item.update!(cooldown_duration: choice)
      redirect_to item_path(@item), success: t("flash.items.cooldown.success")
    else
      flash.now[:alert] = t("flash.items.cooldown.failure")
      render :cooldown, status: :unprocessable_entity
    end
  end

  # 購入判断
  # フォーム表示用
  def purchase_decision
    @questions = Question.where(user_id: nil).order(:position)
    @answers_map = @item.answers.index_by(&:question_id)
    @journal = @item.journal || @item.build_journal

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
      save_item(:drafting)
      redirect_to item_path(@item), success: t("flash.items.decide.success.draft")

    # 購入判断完了
    when "complete"
      status_params = params.dig(:item, :status)

      # バリデーションエラー(購入判断完了時は「買う・買わない」の選択が必要)
      if status_params.blank?
        @item.errors.add(:base, t("flash.items.decide.validation.status_required"))

        @item.assign_attributes(item_params)

        @questions = Question.where(user_id: nil).order(:position)
        @answers_map = build_answers_from_params

        build_journal_from_params

        render :purchase_decision, status: :unprocessable_entity

      # バリデーションOK(購入判断「買う・買わない」を選択済み)
      else
        # 登録成功
        save_item(status_params)
        redirect_to dashboards_path, success: t("flash.items.decide.success.complete")
      end
    end

  # 登録失敗
  rescue ActiveRecord::RecordInvalid
    @item.assign_attributes(item_params)
    @answers_map = build_answers_from_params
    build_journal_from_params

    flash.now[:alert] = t("flash.items.decide.failure")
    render :purchase_decision, status: :unprocessable_entity
  end

  private

  def save_item(status)
    ActiveRecord::Base.transaction do
      @item.assign_attributes(
        status: status,
        desire_level: params.dig(:item, :desire_level),
        current_mood: params.dig(:item, :current_mood)
      )

      if @item.decided? && @item.decided_at.blank?
        @item.decided_at = Time.current
      end

      @item.save!

      save_answers
      save_journal
    end
  end

  def save_answers
    return if answers_params.blank?

    answers_params.each do |_, answer_param|
      next if answer_param[:choice].blank?

      answer = @item.answers.find_or_initialize_by(
        question_id: answer_param["question_id"]
      )

      answer.update!(choice: answer_param[:choice])
    end
  end

  def save_journal
    journal = @item.journal || @item.build_journal

    if journal_content.blank?
      journal.destroy! if journal.persisted?
      return
    end

    journal.update!(content: journal_content)
  end

  # 購入判断完了ボタンをクリック後、失敗した場合(バリデーションエラーまたは登録失敗)
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

  def set_item
    @item = current_user.items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to items_path, alert: t("flash.items.not_found")
  end

  # 既にクールダウンタイマーを使用している場合は遷移できない
  def ensure_cooldown_not_set
    return if @item.cooldown_duration.nil?

    redirect_to item_path(@item), alert: t("flash.items.cooldown.validation.already_used")
  end

  # クールダウン完了前は遷移できない
  def ensure_ready_for_decision
    return if @item.ready_for_decision?

    redirect_to item_path(@item), alert: t("flash.items.decide.access_denied.cooldown_active")
  end

  # 購入判断完了後は遷移できない
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
