# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# db/seeds.rb
default_questions = [
  "似た商品をすでに持っていますか？",
  "今すぐ必要なものですか？",
  "他の商品に比べて安いと感じますか？",
  "購入しても収入や貯蓄に余裕はありますか？",
  "今の気分が欲しい気持ちに影響していると感じますか？",
  "購入しないと後悔すると思いますか？",
  "他の商品や方法で、代わりになる可能性はありますか？",
  "購入することであなたにとって良い影響がありますか？"
]

questions.each_with_index do |content, position|
  question = Question.find_or_initialize_by(user_id: nil, position: position)
  question.content = content
  question.save!
end
