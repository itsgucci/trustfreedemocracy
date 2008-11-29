module Wice
  
  module Defaults
    
    # Style of the view helper.
    # False is a usual view helper
    # True will allow to embed erb content in column (cell) definitions
    ERB_MODE = false
    
    
    # Default number of rows to show per page
    PER_PAGE = 10
    
    # Default order direction
    ORDER_DIRECTION = 'asc'
    
    # Default name for a grid. A grid name is the basis for a lot of
    # names including parameter names, DOM IDs, etc
    # The shorter the name is the shorter the request URI will be
    GRID_NAME = 'grid'
    
    
    SHOW_HIDE_FILTER_ICON = 'icons/grid/page_white_find.png'
    
    SHOW_FILTER_TOOLTIP = 'Show filter'
    HIDE_FILTER_TOOLTIP = 'Hide filter'
    CSV_EXPORT_TOOLTIP  = 'Export to CSV'
    
    # Icon to trigger filtering
    FILTER_ICON = 'icons/grid/table_refresh.png'
    
    # Icon to reset the filter
    RESET_ICON = "icons/grid/table.png"

    # Icon to reset the filter
    TOGGLE_MULTI_SELECT_ICON = "/images/icons/grid/expand.png"

    # CSV Export icon
    CSV_EXPORT_ICON = "/images/icons/grid/page_white_excel.png"

    
    FILTER_TOOLTIP = "Filter"
    RESET_FILTER_TOOLTIP = "Reset"
    
    # The label of the first option of a custom dropdown list meaning 'All items'
    CUSTOM_FILTER_ALL_LABEL = '--'
    
    BOOLEAN_FILTER_TRUE_LABEL  = 'yes'
    BOOLEAN_FILTER_FALSE_LABEL = 'no'
    
    # Show the upper pagination panel by default or not
    SHOW_UPPER_PAGINATION_PANEL = false


    # Enabling CSV export by default
    ENABLE_EXPORT_TO_CSV = false

    
    # The strategy when to show the filter.
    # 
    # :when_filtered - when the table is the result of filtering
    # :always        - show the filter always
    # :no            - never show the filter
    SHOW_FILTER = :when_filtered
    
  end
end