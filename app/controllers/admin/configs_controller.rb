class Admin::ConfigsController < ApplicationController
  
  def index
    @configs = Radiant::Config.find_all_as_tree
  end
  
  def new
  end
  
  def create
    @conf = Radiant::Config.find_or_create_by_key(params[:conf]['key'])
    @conf.update_attributes(params[:conf])
    flash[:notice] = "The config \"#{@conf.key}\" was created."
    redirect_to admin_configs_url
  end
  
  def edit
    @conf = Radiant::Config.find(params[:id])
  end
  
  def update
    Radiant::Config.find(params[:id]).update_attribute(:value, params[:conf][:value])
    redirect_to admin_configs_url
  end
  
  def destroy
    @conf = Radiant::Config.find(params[:id])
    @key = @conf.key
    @conf.destroy
    flash[:notice] = "The config \"#{@key}\" was deleted."
    redirect_to admin_configs_url
  end
  
end
