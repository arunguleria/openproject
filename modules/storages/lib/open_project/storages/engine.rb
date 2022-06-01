#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# See also: Getting started with Engines: https://guides.rubyonrails.org/engines.html
# This file got generated by the open_project:plugin generator.
# It is loaded by `modules/storages/lib/open_project/storages.rb` when the plugin
# gets loaded.
module OpenProject::Storages
  class Engine < ::Rails::Engine
    # engine name is used as a default prefix for module tables when generating
    # tables with the rails command.
    # It may also be used in other places, please investigate.
    engine_name :openproject_storages

    # please see comments inside ActsAsOpEngine class
    include OpenProject::Plugins::ActsAsOpEngine

    # For documentation see the definition of register in "ActsAsOpEngine"
    # This corresponds to the openproject-storage.gemspec
    # Pass a block to the plugin (for defining permissions, menu items and the like)
    register 'openproject-storages',
             author_url: 'https://www.openproject.org',
             bundled: true,
             settings: {},
             name: 'OpenProject Storages' do
      # Defines permission constraints used in the module (controller, etc.)
      # Permissions documentation: https://www.openproject.org/docs/development/concepts/permissions/#definition-of-permissions
      project_module :storages,
                     dependencies: :work_package_tracking,
                     if: ->(*) { OpenProject::FeatureDecisions.storages_module_active? } do
        permission :view_file_links,
                   {},
                   dependencies: %i[view_work_packages]
        permission :manage_file_links,
                   {},
                   dependencies: %i[view_file_links]
        permission :manage_storages_in_project,
                   { 'storages/admin/projects_storages': %i[index new create destroy] },
                   dependencies: %i[]
      end

      # Menu extensions
      # Add a "storages_admin_settings" to the admin_menu with the specified link,
      # condition ("if:"), caption and icon.
      menu :admin_menu,
           :storages_admin_settings,
           { controller: '/storages/admin/storages', action: :index },
           if: Proc.new { User.current.admin? && OpenProject::FeatureDecisions.storages_module_active? },
           caption: :project_module_storages,
           icon: 'icon2 icon-hosting'

      menu :project_menu,
           :settings_projects_storages,
           { controller: '/storages/admin/projects_storages', action: 'index' },
           if: Proc.new { OpenProject::FeatureDecisions.storages_module_active? },
           caption: :project_module_storages,
           parent: :settings
    end

    patch_with_namespace :Principals, :ReplaceReferencesService
    patch_with_namespace :BasicData, :RoleSeeder

    # This hook is executed when the module is loaded.
    config.to_prepare do
      # We have a bunch of filters defined within the module. Here we register the filters.
      ::Queries::Register.register(::Query) do
        [
          ::Queries::Storages::WorkPackages::Filter::FileLinkOriginIdFilter,
          ::Queries::Storages::WorkPackages::Filter::StorageIdFilter,
          ::Queries::Storages::WorkPackages::Filter::StorageUrlFilter,
          ::Queries::Storages::WorkPackages::Filter::LinkableToStorageIdFilter,
          ::Queries::Storages::WorkPackages::Filter::LinkableToStorageUrlFilter
        ].each do |filter|
          filter filter
          exclude filter
        end

        ::Queries::Register.register(::Queries::Storages::FileLinks::FileLinkQuery) do
          filter ::Queries::Storages::FileLinks::Filter::StorageFilter
        end
      end
    end

    # This helper methods adds a method on the `api_v3_paths` helper. It is created with one parameter (storage_id)
    # and the return value is a string.
    add_api_path :storage do |storage_id|
      "#{root}/storages/#{storage_id}"
    end

    add_api_path :file_links do |work_package_id|
      "#{work_package(work_package_id)}/file_links"
    end

    add_api_path :file_link do |file_link_id|
      "#{root}/file_links/#{file_link_id}"
    end

    add_api_path :file_link_download do |file_link_id|
      "#{root}/file_links/#{file_link_id}/download"
    end

    add_api_path :file_link_open do |file_link_id, location = false|
      "#{root}/file_links/#{file_link_id}/open#{location ? '?location=true' : ''}"
    end

    # Add api endpoints specific to this module
    add_api_endpoint 'API::V3::Root' do
      mount ::API::V3::Storages::StoragesAPI
      mount ::API::V3::FileLinks::FileLinksAPI
    end

    add_api_endpoint 'API::V3::WorkPackages::WorkPackagesAPI', :id do
      mount ::API::V3::FileLinks::WorkPackagesFileLinksAPI
    end
  end
end
