class CreateDreamTags < ActiveRecord::Migration[7.2]
  def change
    create_table :dream_tags, comment: 'DreamとTagの多対多関係' do |t|
      t.references :dream, null: false, foreign_key: true, comment: '夢日記ID'
      t.references :tag, null: false, foreign_key: true, comment: 'タグID'

      t.timestamps null: false, comment: '作成日時・更新日時'

      t.index [:dream_id, :tag_id], unique: true
    end
  end
end
