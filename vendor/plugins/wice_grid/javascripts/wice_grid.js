WiceGridProcessor = Class.create();

Object.extend(WiceGridProcessor.prototype, {
	initialize : function(name, base_request_for_filter, link_for_export){
		this.name = name;
		this.base_request_for_filter = base_request_for_filter;
		this.link_for_export = link_for_export;
		this.column_callbacks = new Array();
	},
	
	process : function(){
		results = new Array();
		this.column_callbacks.each(function(k){
			param = k();
			if (param && ! param.empty()){
				results.push(param);
			}
		});
		
		if ( results.size() != 0){
			all_filter_params = results.join('&');
			if (this.base_request_for_filter.include('?')){
				if (/\?$/.exec(this.base_request_for_filter)){
					separator = '';
				}else{
					separator = '&';
				}
			}else{
				separator = '?';
			}
			request_for_filter = this.base_request_for_filter + separator + all_filter_params;
		}else{
			request_for_filter = this.base_request_for_filter;
		}
		window.location = request_for_filter;
	},
	
	reset : function(){
		window.location = this.base_request_for_filter;
	},

	export_to_csv : function(){
		window.location = this.link_for_export;
	},

	
	register : function(func){
		this.column_callbacks.push(func);
	},
		
	read_values_and_form_query_string : function(templates, ids){
		res = new Array();
		for(i = 0; i < templates.length; i++){
			val = $F(ids[i]);
			if (val instanceof Array) {
				for(j = 0; j < val.length; j++){
					res.push(templates[i] + val[j]);
				}
			} else if (val && ! val.empty()){
				res.push(templates[i]  + val);
			}
		}
		return res.join('&');
	}
	
});

function toggle_multi_select(select_id, link_obj, expand_label, collapse_label) {
	select = $(select_id);
	if (select.multiple == true) {
		select.multiple = false;
		link_obj.title = expand_label;
	} else {
		select.multiple = true;
		link_obj.title = collapse_label;
	}
}
