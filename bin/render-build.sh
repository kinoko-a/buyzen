set -o errexit

bundle install
npm run build:js:prod
npm run build:css:prod
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
bundle exec rails db:seed