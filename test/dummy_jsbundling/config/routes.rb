Rails.application.routes.draw do
  root "advanced_select_examples#show"
  get "advanced_select_examples/options", to: "advanced_select_examples#options", as: :advanced_select_example_options
end
