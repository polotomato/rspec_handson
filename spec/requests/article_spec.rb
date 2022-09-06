require 'rails_helper'

RSpec.describe "Articles", type: :request do
  let!(:article1) { FactoryBot.create(:article, title: "今日の天気", content:"晴れ") }
  let!(:article2) { FactoryBot.create(:article, title: "明日の天気", content:"曇り") }
  let!(:article3) { FactoryBot.create(:article, title: "明後日の天気", content:"雨") }

  context 'index.jsonを呼び出す' do
    it "保存された Article が全件取得できる" do
      get "/articles.json" 
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).length).to eq(3)
    end
  end
end
