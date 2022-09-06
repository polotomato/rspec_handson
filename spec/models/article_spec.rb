require 'rails_helper'

RSpec.describe Article, type: :model do
  context 'titleとcontentが両方存在する場合' do
    let(:article) do
      Article.new({ title: '今日の天気', content: '晴れ' })
    end
    it '登録可能であること' do
      expect(article).to be_valid
    end
  end
end
