class CreateDreams < ActiveRecord::Migration[7.2]
  def change
    create_table :dreams, comment: '夢日記の本体データ' do |t|
      t.references :user, null: false, foreign_key: true, comment: 'ユーザーID'
      t.string :title, null: false, limit: 15, comment: '夢のタイトル（15文字制限）'
      t.text :content, null: false, comment: '夢の本文（10,000文字制限）'
      t.integer :emotion_color, null: false, comment: '感情彩色（enum: 0=peace, 1=chaos, 2=fear, 3=elation）'
      t.boolean :lucid_dream_flag, default: false, comment: '明晰夢フラグ'
      t.datetime :dreamed_at, null: false, comment: '夢を見た日'

      t.timestamps null: false, comment: '作成日時・更新日時'

      t.index [:user_id, :dreamed_at]
      t.index [:user_id, :emotion_color]
      t.index [:user_id, :title]
    end
  end
end
