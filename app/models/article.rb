class Article < ApplicationRecord
  validates :title, presence: true
  validates :title, length: { minimum:2, maximum: 10 }
  validates :content, presence: true
end
