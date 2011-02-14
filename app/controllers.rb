module Journ::Controllers
    class AutoComplete < R '/auto'
        def get
            topics = Models::Topic.filter(:topic.like "%#{@input.post_topics}%")
            mab do
                ul_ do
                    topics.map do |t|
                        li_{h t.topic}
                    end
                end
            end
        end
    end
    class Index < R '/index'
        def get
            render :index
        end
    end
    class Search < R '/search'
        def get
            page=(@input.page || 1).to_i
            @posts = Models::Post.order(:created_at.desc)

            @q = @input.q
            @topic_id=@input.topic_id
            q = "%#{@q}%"
            if @topic_id and @topic_id != '0'
                @topic = Topic[@topic_id]
                @posts = @topic.posts_dataset.filter("post like ?", q)
            elsif @topic_id=='0'
                @topic = Models::Topic.new :topic=>'Unclassified'
                @posts = Post.all_unclassified.filter("post like ?", q)
            elsif @input.start_date
                @start_date = @input.start_date
                y, m = @start_date.split('-')
                y, m = y.to_i, m.to_i
                dt1 = Date.new(y, m, 1)
                @posts=Models::Post.filter(:created_at=>((dt1)..(dt1>>1))).order(:created_at.desc)
            else
                @posts = @posts.filter("post like ?", q)
            end
            @posts = @posts.paginate(page, Journ::MAX_POSTS)
            if @input.wants_js
                render :_search
            else
                render :search
            end
        end
    end
    LoadMore = Search

    class TopicsIndex < R '/'
        def get
            page=(@input.page || 1).to_i
            @topics = Models::Topic.order(:topic)
            if @topics.count.zero?
                render :index
            else
                render :index_topics
            end
        end
    end
    class Topics < R '/topics', '/topics/(\w+)'
        def get topic_id

            page=(@input.page || 1).to_i
            if topic_id.to_i.zero?
                @topic = Models::Topic.new :topic=>'Unclassified'
                @topic_id = 0
                @topic_posts = Post.all_unclassified.paginate(page, Journ::MAX_POSTS)
            else
                @topic = Models::Topic[topic_id]
                @topic_id = @topic[:id]
                @topic_posts = @topic.posts_dataset.paginate(page, Journ::MAX_POSTS)
            end
            if @input.wants_js
                render :_view_topic, @topic
            else
                render :view_topic
            end

        end
        def post
            @topic = Models::Topic.find_or_create :topic=>@input.topic, :post_post=>@input.post_post
            redirect Topics, @topic
        end
    end
    class Posts < R '/posts', '/posts/(\w+)'
        def get post_id
            page = (@input.page || 1).to_i
            @post = Models::Post[post_id]
            @render_method  = @input.render_method
            @post_descendants = @post.descendants.paginate(page, Journ::MAX_POSTS)
            if @render_method
                render @render_method, @post
            else
                render :view_post
            end
        end
        def post
            @post = Post.create :post=>@input.post,  :post_topics=>@input.post_topics
            redirect Posts, @post
        end
        def put post_id
            @post = Models::Post[post_id]
            @post.modified! # needed for post_topics update to take effect
            @post.update :post=>@input.post , :post_topics=>@input.post_topics
            redirect Posts, @post
        end
        def delete post_id
            @post=Models::Post[post_id]
            @post.delete
            redirect TopicsIndex, :page=>@state[:current_page]
        end
    end
    class Reply < R '/reply/to', '/reply/to/(\w+)'
        def get post_id
            @post = Models::Post[post_id]
            render :reply
        end
        def post post_id
            post = Models::Post[post_id]
            child = post.add_child :post=>@input.post, :post_topics=>post.topic_names
            redirect Posts, child
        end
    end
    class Follow < R '/follow', '/follow/(\w+)'
        def get topic_id
            mab true do
                div_ :class=>'form-input-box' do
                    form_ :action=>R(Follow), :method=>'post' do
                        input_ :type=>'hidden', :name=>'topic_id', :value=>topic_id
                        label_ 'followings'
                        input_ :type=>'text', :name=>'followings', :id=>'auto-followings'
                        input_ :type=>'submit', :value=>'follow'
                    end
                end
                div_ '', :class=>'autocomplete', :id=>'auto-followings-div'
            end
        end
    end
end
