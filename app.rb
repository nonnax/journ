$: << 'lib/'
gem 'camping', '<=2.0'
require 'campr'
require 'redcloth'
require 'pp'

Camping.goes :Journ, :database=>'db/journ.sqlite3'

require 'app/helpers'
require 'app/models'
require 'app/controllers'

module Journ
    MAX_POSTS = 30
    include Camping::Session
end

module Journ::Views

    def layout
        title=if @topic and @topic.topic!='Unclassified' then
            "#{@topic.try(:topic)} (#{@topic.try(:posts_dataset).try(:count)})"
        elsif @post
            @post.title
        else
            'Journ:'<< Journ::Models::Post.count.to_s
        end
        html_ do
            head_ do
                title_ title
                link_   '', :rel=>'stylesheet', :type=>'text/css',  :href=>'/css/style.css'
                link_   '', :rel=>'icon',       :type=>'image/png', :href=>'/images/favicon.png'
               %w[prototype scriptaculous ajax_helpers utils datetimepicker].each do |s|
                  script_('', :src => "/js/#{s}.js", :type => 'text/javascript')
               end

            end
            body_ do
                div_ :id=>'nav' do
                    div_ :class=>'menu' do
                        a_ 'home', :href=>R(TopicsIndex)
                        b_space
                        a_ 'new', :href=>R(Index)
                    end
                    _search_form()
                end
                div_ :id=>'content' do
                    yield
                end
            end
        end
    end

    def index
        _form_post nil, :action=>R(Posts), :method=>'post'
    end

    def search
        _search
    end

    def index_topics # or as index_tags
        span_ 'found: '
        span_ '('+Journ::Models::Post.count.to_s+')'
        span_ ' '
        hr_
        a_ '[Unclassified]', :href=>R(Topics, 0)
        b_space
        @topics.map do |t|
            a_ t.topic, :href=>R(Topics, t), :class=>t.popularity
            b_space
        end
        hr_
        p_(:class=>'date-index'){ _index_dates }
    end

    def view_topic
        t = @topic
        div_ :class=>'form-input-box'  do
            form_ :action=>R(Posts), :method=>'post' do
                input_ :type=>'hidden', :name=>'post_topics', :value=>t.try(:topic)
                textarea_ '', :name=>'post', :id=>'post-input'
                br_
                input_ :type=>'submit', :value=>'add post'
            end
        end
        h2_ t.try(:topic)
        _view_topic @topic
    end

    def view_post
        h2_ do
            @post.root.topics.each do |t|
                a_ "[#{t.topic}]", :href=>R(Topics, t)
            end
        end
        div_ :class=>'view-post' do
            @post.ancestors.map{ |a| li_{ _view_simple a}}
            li_{ _view_full  @post, :allow_reply=>true }
            @post_descendants.map{ |r| li_{ _view_simple r}}
            _pagination @post_descendants, :href=>[Posts, @post]
        end
    end

    def reply
        div_ do
            h1_{ @post.title.h}
            h4_ do
                a_ "[thread]" , :href=>R(Posts, @post.root)
            end
            if @post.prev_post[:id] != @post[:id]
                _span_prev
                a_ "#{@post.prev_post.title.h}", :href=>R(Reply, @post.prev_post)
            end
            hr_
            _view_full @post
            br_
            div_ :class=>'form-input-box' do
                form_ :action=>R(Reply, @post), :method=>'post' do
                    input_ :type=>'hidden', :name=>'post_id', :value=>@post.id
                    textarea_ '', :name=>'post', :id=>'post-input'
                    br_
                    input_ :type=>'submit', :value=>'reply'
                end
            end
            hr_
            if @post.next_post
                _span_next
                a_ " #{@post.next_post.title.h}" , :href=>R(Reply, @post.next_post)
            end
        end
    end

    def edit_post post
        _modify_post post, :_form_post
    end
    def delete_post post
        _modify_post post, :_form_delete
    end

    # --------------------------------------------------------
    #    view partials
    # --------------------------------------------------------

    ## _record_found_header
    # client: _search
    # client: _view_topic
    #
    def _record_found_header posts
        hr_
        span_ 'found: '
        span_ '('+posts.pagination_record_count.to_s+')'
        b_space
        span_ posts.current_page_record_range
    end
    ## _search
    # client: search
    #
    def _search
        _record_found_header @posts
        br_
        i=0
        i.acts_as_toggle
        @posts.each do |p|
            li_(:class=>"t#{i.toggle}") do
                p.topics.each do |topic|
                    span_{ a_ "[#{topic.topic}]", :href=>R(Topics, topic)}
                end
                b_space
                _view_raw p
            end
        end
        params = [self.class]
        params << {:q=>@q} if @q
        params << {:topic_id=>@topic_id} if @topic_id
        params << {:start_date=>@start_date} if @start_date
        _pagination_ajax @posts, :href=>params
    end

    ## _view_topic
    # client: view_topic
    #
    def _view_topic t
        _record_found_header @topic_posts
        br_
        i=0
        i.acts_as_toggle
        @topic_posts.map do |p|
            li_(:class=>"t#{i.toggle}"){ _view_raw p}
        end
        h={:href=>[Topics, t]}
        h={:href=>[Topics, 0]} if t.topic=='Unclassified'

        _pagination_ajax @topic_posts, h
    end

    ## _modify_post
    # client: edit_post
    # client: delete_post
    #
    def _modify_post post, form_method
        div_ do
            h4_ do
                a_ "[thread]" , :href=>R(Posts, post.root)
            end
            if post.prev_post[:id] != post[:id]
                _span_prev
                a_ "#{post.prev_post.title.h}", :href=>R(Reply, post.prev_post)
            end
            hr_
            send( form_method, post )
            hr_
            if post.next_post
                _span_next
                a_ " #{post.next_post.title.h}" , :href=>R(Reply, post.next_post)
            end
        end
    end

    ## _index_dates
    # client: index_topics
    #
    def _index_dates
        yclass=0
        h = Journ::Models::Post.year_month
        h.each do |k, v|
            yclass = 1-yclass
            span_( :class=>"y#{yclass}") do
                b_ k
                b_space
                v.each do |m|
                    sdate = "%02d" % [m]
                    a_ sdate, :href=>R(Search, :start_date=>"#{k}-#{m}", :q=>'')
                    b_space
                end
            end
        end
    end

    ## _search_form
    # client: layout
    #

    def _search_form
        div_ :class=>'form-search-box' do
            form_ :action=>R(Search), :class=>'form-search'  do
                label_ @topic.try(:topic) || 'find'
                span_ ' &nbsp; '
                input_ :type=>'hidden', :name=>'topic_id', :value=>@topic_id if @topic_id
                input_ :type=>'text', :name=>'q'
                div_ :class=>'buttons' do
                    input_ :type=>'submit'
                end
            end
        end
    end

    ## _view_full
    # client: view_post
    # client: reply
    #
    def _view_full post, h={}
        _view post do |post|
            span_ post.created_at.to_words, :class=>'timestamp'
            b_space
            a_ '[reply]',  :href=>R(Reply, post) if h[:allow_reply]
            b_space
            a_ '[edit]',   :href=>R(Posts, post, :render_method=>:edit_post)
            b_space
            a_ '[x]',      :href=>R(Posts, post, :render_method=>:delete_post)
            b_space
            div_ :class=>'view-post' do
                markup(post.post)
            end
            div_ do
                post.topics.map{|t| a_( t.topic, :href=>R(Topics,t), :class=>'topic tags'); b_space }
            end
        end
    end

    ## _view_simple
    # client: view_post
    #
    def _view_simple post, h={}
        _view post do |post|
            span_ post.created_at.to_words, :class=>'timestamp'
            b_space
            a_ post.title.h, :href=>R(Reply, post), :class=>'post'
        end
    end

    ### _view
    # client: _view_full
    # client: _view_simple
    #
    def _view post, &b
        div_ :class=>"L#{(post.path_depth)} post" do
            b.call(post)
        end
    end

    ## _view_raw
    # client: _view_topic
    # client: _search
    #
    def _view_raw post, h={}
        # no indentation div
        div_ :class=>'raw-post'  do
            span_ post.created_at.to_words, :class=>'timestamp'
            b_space
            a_ post.title.h, :href=>R(Reply, post), :class=>"post  #{post.parent_id.zero? ? 'parent' : ''}"
        end
    end

    ## _form_post
    # client: index
    # client: edit_post
    #
    def _form_post post, h={}
        h[:method] ||= 'put'
        h[:action] ||= R(Posts, post)
        rows=post.post.scan(/\n/).flatten.size rescue nil
        div_ :class=>'form-input-box' do
            form_ h do
                textarea_ post.try(:post), :name=>'post', :rows=>rows, :id=>'post-input'
                br_
                input_ :type=>'text', :name=>'post_topics', :value=>post.try(:topic_names), :id=>'post-topics'
                label_ 'topics'
                br_
                input_ :type=>'submit', :value=>'save'
            end
        end
        div_ :id=>'auto-topics' do
          "&nbsp;"
        end
    end

    ## _form_delete
    # client: delete_post
    #
    def _form_delete post
        div_ :class=>"L#{(post.path_depth)}" do
            div_ :class=>'form-input-box' do
                form_ :action=>R(Posts, post), :method=>'delete' do
                    textarea_ post.post, :name=>'post'
                    br_
                    input_ :type=>'submit', :value=>'Delete'
                end
            end
        end
    end
end

Camping.start :port=>3301
