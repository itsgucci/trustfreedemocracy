# taken from comatose, thanks!
class ActionController::Routing::RouteSet::Mapper

  def badges_admin(path='badges', options={})
    define_named_routes(path, 'badges', 'admin', options)
  end
  
  protected 

  def define_named_routes(path, mod, controller, options)
    opts = {:controller=>"#{mod}/#{controller}"}.merge(options)
    named_route("#{mod}_#{controller}", "#{path}/#{controller}/:action",  opts)
    named_route("#{mod}_#{controller}", "#{path}/#{controller}/:action/:id", opts )
    named_route("#{mod}_#{controller}", "#{path}/#{controller}/:action/:id.:format", opts )
  end

end
