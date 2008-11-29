namespace "wice_grid" do
  desc "Copy images, the javascript file, and the stylesheet file to public"
  task :copy_resources_to_public do
    puts "copying wice_grid.js to /public/javascripts/"
    FileUtils.copy(
      File.join(RAILS_ROOT,  '/vendor/plugins/wice_grid/javascripts/wice_grid.js'), 
      File.join(RAILS_ROOT,  '/public/javascripts/')
    )
    puts "copying wice_grid.css to /public/stylesheets/"    
    FileUtils.copy(
      File.join(RAILS_ROOT,  '/vendor/plugins/wice_grid/stylesheets/wice_grid.css'), 
      File.join(RAILS_ROOT,  '/public/stylesheets/')
    )

    FileUtils.mkdir_p(File.join(RAILS_ROOT,  "/public/images/icons/grid"))
    
    %w( arrow_down.gif arrow_up.gif page_white_find.png table.png table_refresh.png expand.png page_white_excel.png ).each do |file|
      puts "copying #{file} to /public/images/icons/grid"   
      FileUtils.copy(
        File.join(RAILS_ROOT,  "/vendor/plugins/wice_grid/images/#{file}"), 
        File.join(RAILS_ROOT,  '/public/images/icons/grid')
      )
    end
  end
end