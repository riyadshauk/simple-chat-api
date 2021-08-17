/*
  Need this file to get graphiql-rails to work on API-mode Rails project:
  https://github.com/leofrozenyogurt/graphiql-rails#note-on-api-mode
  https://github.com/rails/sprockets/blob/070fc01947c111d35bb4c836e9bb71962a8e0595/UPGRADING.md#manifestjs
  https://github.com/rmosolgo/graphiql-rails/issues/75#issuecomment-546306742
*/

// app/assets/config/manifest.js
//
//= link graphiql/rails/application.js
//= link graphiql/rails/application.css
