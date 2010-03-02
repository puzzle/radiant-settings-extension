namespace :radiant do
  namespace :extensions do
    namespace :conf do
      
      desc "Runs the migration of the Conf extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          ConfigsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          ConfigsExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Conf to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        Dir[ConfigsExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(ConfigsExtension.root, '')
          directory = File.dirname(path)
          puts "Copying #{path}..."
          mkdir_p RAILS_ROOT + directory
          cp file, RAILS_ROOT + path
        end
      end

    end
  end
end

namespace :db do
  task :import do
    require 'highline/import'
    Rake::Task["db:schema:load"].invoke
    # Use what Radiant::Setup for the heavy lifting
    require 'radiant/setup'
    require 'lib/radiant_setup_create_records_patch'
    setup = Radiant::Setup.new
    
    # Load the data from the export file
    data = YAML.load_file(ENV['TEMPLATE'] || "#{RAILS_ROOT}/db/export.yml")
    
    # Load the users first so created_by fields can be updated
    users_only = {'records' => {'Users' => data['records'].delete('Users')}}
    passwords = []
    users_only['records']['Users'].each do |id, attributes|
      if attributes['password']
        passwords << [attributes['id'], attributes['password'], attributes['salt']]
        attributes['password'] = 'radiant'
        attributes['password_confirmation'] = 'radiant'
      end
    end
    setup.send :create_records, users_only
    
    # Hack to get passwords transferred correctly.
    passwords.each do |id, password, salt|
      User.update_all({:password => password, :salt => salt}, ['id = ?', id])
    end
    

    # Now load the created users into the hash and load the rest of the data
    data['records'].each do |klass, records|
      records.each do |key, attributes|
        if attributes.has_key? 'created_by'
          attributes['created_by'] = User.find(attributes['created_by']) rescue nil
        end
        if attributes.has_key? 'updated_by'
          attributes['updated_by'] = User.find(attributes['updated_by']) rescue nil
        end
        if attributes.has_key? 'clear_password'
          #attributes['password'] = attributes['password_confirmation'] = attributes['clear_password']
        end
      end
    end
    setup.send :create_records, data
  end
  
  task :export => ["db:schema:dump"] do
    template_name = ENV['TEMPLATE'] || "#{RAILS_ROOT}/db/export.yml"
    File.open(template_name, "w") {|f| f.write Exporter.export }
  end
end