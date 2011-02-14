module Journ::Helpers
    def _pagination(pages, h={})
        return unless pages.page_count > 1
        @state[:current_page] = pages.current_page
        a = (h[:href] ||= [self])
        div_(:class=>'pages') do
            a_ '&lsaquo; prev',     :href=>Route(a, :page=>pages.prev_page || 1)
            a_ '&laquo; 1',                 :href=>Route(a, :page=>1)
            b_ '...'
            a_ pages.prev_page,   :href=>Route(a, :page=>pages.prev_page) if pages.prev_page
            a_ pages.current_page,:class=>'current-page'
            a_ pages.next_page,   :href=>Route(a, :page=>pages.next_page) if pages.next_page
            b_ '...'
            a_ "#{pages.page_count} &raquo;",  :href=>Route(a, :page=>pages.page_count)
            a_ 'next &rsaquo;',     :href=>Route(a, :page=>pages.next_page || pages.page_count)
        end
    end
    def _pagination_ajax(pages, h={})
        return unless pages.page_count > 1
        @state[:current_page] = pages.current_page
        a = (h[:href] ||= [@env['REQUEST_URI']])
        div_(:id=>'pagination') do
            a_ '&laquo; 1',                 :href=>Route(a, :page=>1)
            b_ '...'
            a_ pages.prev_page,   :href=>Route(a, :page=>pages.prev_page) if pages.prev_page
            a_ pages.current_page, :class=>'current-page'
            a_ pages.next_page,   :href=>'#', :onclick=>Updater('pagination', Route(a, :wants_js=>1, :page=>pages.next_page)) if pages.next_page
            b_ '...'
            a_ "#{pages.page_count} &raquo;",  :href=>Route(a, :page=>pages.page_count)
            div_ :id=>'loadmore' do
                '&nbsp;'
            end
        end
    end

    def b_space
        b_ ' '
    end

    def _span_prev
        span_ '&lt; Prev: '
    end

    def _span_next
        span_ 'Next: &gt;'
    end

    private
    def Route(*a)
        # like the regular R() but accepts/merges sets of hashes
        a.flatten!
        h=a.grep(Hash)
        a-=h
        R(*[a, h.inject({}){|m,x| m.merge x}].flatten)
    end
    def markup s
        RedCloth.new(s).to_html
    end
end
