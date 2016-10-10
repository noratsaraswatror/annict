# frozen_string_literal: true

module Db
  class WorksController < Db::ApplicationController
    permits :title, :title_kana, :title_ro, :title_en, :media, :season_id,
      :official_site_url, :official_site_en_url, :wikipedia_url, :wikipedia_en_url,
      :twitter_username, :twitter_hashtag, :sc_tid, :mal_anime_id, :number_format_id,
      :synopsis, :synopsis_source, :synopsis_en, :synopsis_en_source

    before_action :authenticate_user!, only: [:new, :create, :edit, :update, :destroy]

    def index(page: nil)
      @works = Work.includes(:season, :item).order(id: :desc).page(page)
    end

    def season(page: nil, slug: ENV["ANNICT_CURRENT_SEASON"])
      @works = Work.includes(:season, :item).by_season(slug).order(id: :desc).page(page)
      render :index
    end

    def resourceless(page: nil, name: "episode")
      @works = case name
      when "episode" then Work.includes(:season, :item).where(episodes_count: 0)
      when "item" then Work.includes(:season, :item).itemless.includes(:item)
      end
      @works = @works.order(watchers_count: :desc).page(page)
      render :index
    end

    def new
      @work = Work.new
      authorize @work, :new?
    end

    def create(work)
      @work = Work.new(work)
      @work.user = current_user
      authorize @work, :create?

      return render(:new) unless @work.valid?
      @work.save_and_create_activity!

      redirect_to edit_db_work_path(@work), notice: t("resources.work.created")
    end

    def edit(id)
      @work = Work.find(id)
      authorize @work, :edit?
    end

    def update(id, work)
      @work = Work.find(id)
      authorize @work, :update?

      @work.attributes = work
      @work.user = current_user

      return render(:edit) unless @work.valid?
      @work.save_and_create_activity!

      redirect_to edit_db_work_path(@work), notice: t("resources.work.updated")
    end

    def hide(id)
      @work = Work.find(id)
      authorize @work, :hide?

      @work.hide!

      redirect_to :back, notice: "作品を非公開にしました"
    end

    def destroy(id)
      @work = Work.find(id)
      authorize @work, :destroy?

      @work.destroy

      redirect_to db_works_path, notice: "作品を削除しました"
    end
  end
end
