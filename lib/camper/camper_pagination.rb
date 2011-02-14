module Camping::PaginationHelper
   def _pagination(pages, h={})
      @state[:current_page] = pages.current_page
      Hash===h ? h : h={}
      div_(:class=>'pages') do
         span_ 'page: '
         a_ pages.prev_page && '|&laquo;', :href=>R(self.class, h.merge(:page=>1))
         a_ pages.prev_page.try(:pred), :href=>R(self.class, h.merge(:page=>pages.prev_page.try(:pred))) if pages.page_range===pages.prev_page.try(:pred)
         a_ pages.prev_page, :href=>R(self.class, h.merge(:page=>pages.prev_page))
         b_ pages.current_page
         a_ pages.next_page, :href=>R(self.class, h.merge(:page=>pages.next_page))
         a_ pages.next_page.try(:succ), :href=>R(self.class, h.merge(:page=>pages.next_page.try(:succ))) if pages.page_range===pages.next_page.try(:succ)
         a_ pages.next_page && '&raquo;|', :href=>R(self.class, h.merge(:page=>pages.page_count))
      end
   end
end

