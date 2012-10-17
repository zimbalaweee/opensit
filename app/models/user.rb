# == Schema Information
#
# Table name: users (NOTE: Devise fields removed)
#
#  id                   :integer          not null, primary key
#  username             :string(255)
#  email                :string(255)
#  profile_pic          :string(255)
#  first_name           :string(255)
#  last_name            :string(255)
#  dob                  :date
#  gender               :integer
#  city                 :string(255)
#  country              :string(255)
#  who                  :text
#  why                  :text
#  style                :text
#  practice             :text
#  public_diary         :boolean
#  default_sit_length   :integer
#  user_type            :integer
#

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  # CarrierWave
  mount_uploader :avatar, AvatarUploader
  
  has_many :sits, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  
  # Overwrite Devise function to allow profile update with password requirement
  # http://stackoverflow.com/questions/4101220/rails-3-devise-how-to-skip-the-current-password-when-editing-a-registratio?rq=1
  def update_with_password(params={}) 
    if params[:password].blank? 
      params.delete(:password) 
      params.delete(:password_confirmation) if params[:password_confirmation].blank? 
    end 
    update_attributes(params) 
  end
end
