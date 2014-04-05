class UsersController < ApplicationController
  before_filter :authenticate_user!, only: [:me, :export, :followers, :following]
  before_filter :check_date, only: :show

  # GET /welcome
  def welcome
    @user = current_user
    @users_to_follow = User.active_users.limit(5)
  end

  # GET /me page
  def me
    @feed_items = current_user.socialstream.paginate(:page => params[:page])
    @user = current_user
    @latest = @user.latest_sits

    @title = 'Home'
    @page_class = 'me'
  end

  # GET /u/buddha or /buddha
  def show
    @user = User.where("lower(username) = lower(?)", params[:username]).first!
    @links = @user.stream_range

    if !@user.private_stream
      if params[:year] && params[:month]
        if current_user == @user
          @sits = @user.sits_by_month(month: params[:month], year: params[:year]).newest_first
        else
          @sits = @user.sits_by_month(month: params[:month], year: params[:year]).public.newest_first
        end
        @range_title = "#{Date::MONTHNAMES[params[:month].to_i]}, #{params[:year]}"
      elsif params[:year]
        if current_user == @user
          @sits = @user.sits_by_year(params[:year]).newest_first
        else
          @sits = @user.sits_by_year(params[:year]).public.newest_first
        end
        @range_title = "All sits in #{params[:year]}"
      else
        if current_user && @user.id == current_user.id
          @sits = @user.sits.newest_first.paginate(:page => params[:page])
        else
          @sits = @user.sits.public.newest_first.paginate(:page => params[:page])
        end
      end
    end

    @title = "#{@user.display_name}\'s meditation practice journal"
    @desc = "#{@user.display_name} has logged #{@user.sits_count} meditation reports on OpenSit, a free community for meditators."
    @page_class = 'view-user'
  end

  # GET /u/buddha/following
  def following
    @user = User.where("lower(username) = lower(?)", params[:username]).first!
    @users = @user.followed_users
    @latest = @user.latest_sits

    if @user == current_user
      @title = "People I follow"
    else
      @title = "People who #{@user.display_name} follows"
    end

    @page_class = 'following'
    render 'show_follow'
  end

  # GET /u/buddha/followers
  def followers
    @user = User.where("lower(username) = lower(?)", params[:username]).first!
    @users = @user.followers
    @latest = @user.latest_sits

    if @user == current_user
      @title = "People who follow me"
    else
      @title = "People who follow #{@user.display_name}"
    end

    @page_class = 'followers'
    render 'show_follow'
  end

  # Generate atom feed for user or all public content (global)
  def feed
    if params[:scope] == 'global'
      @sits = Sit.public.newest_first.limit(50)
      @title = "Global SitStream | OpenSit"
    else
      @user = User.where("lower(username) = lower(?)", params[:username]).first!
      @title = "SitStream for #{@user.username}"
      @sits = @user.sits.public.newest_first.limit(20)
    end

    # This is the feed's update timestamp
    @updated = @sits.last.updated_at unless @sits.empty?

    respond_to do |format|
      format.atom
    end
  end

  # GET /u/buddha/export
  def export
    @user = User.where("lower(username) = lower(?)", params[:username]).first!
    @sits = Sit.where(:user_id => @user.id)

    respond_to do |format|
      format.html
      format.json { render json: @sits }
      format.xml { render xml: @sits }
    end
  end

  private

    # Validate year and month params on user page
    def check_date
      [:year, :month].each do |v|
        if (params[v] && params[v].to_i.zero?) || params[v].to_i > (v == :year ? 3000 : 12)
          unit = v == :year ? 'year' : 'month'
          flash[:error] = "Invalid #{unit}!"
          redirect_to user_path(params[:username])
        end
      end
    end
end
