module Journ::Models
    class Topic < Sequel::Model
        # Note that :left_key refers to the foreign key pointing to the
        # current table, and :right_key the foreign key pointing to the
        # associated table.
        attr_accessor :post_post, :post_title
        one_to_many :postings
        many_to_many :posts,      :join_table=>:postings,  :left_key=>:topic_id,       :right_key=>:post_id, :class =>'Journ::Models::Post', :order=>:posts__created_at.desc

        many_to_many :followings, :join_table=>:relationships, :left_key => :following_id, :right_key => :topic_id,     :class => self
        many_to_many :topics,     :join_table=>:relationships, :left_key => :topic_id,     :right_key => :following_id, :class => self
        def self.find_or_create(h)
            #            p [__method__, h]
            h[:topic] = h[:topic].downcase.strip
            h[:topic] ='default' if h[:topic].blank?

            topic = self.find(:topic=>h[:topic])
            if topic.nil?
                topic = self.create h
            else
                topic.add_post :post=>h[:post_post], :parent_id=>0 if h[:post_post]
            end
            topic
        end
        def popularity
            case postings.count
            when 0..4
                'normal'
            when 5..10
                'popular'
            else
                'hit'
            end
        end
        private
        def after_save
            super
            return if post_post.try(:strip).blank?
            self.add_post :post=>post_post.strip
        end
    end
    class Post < Sequel::Model
        # Note that :left_key refers to the foreign key pointing to the
        # current table, and :right_key the foreign key pointing to the
        # associated table.
        attr_accessor :post_topics
        SPADDING = "%05d"
        many_to_one :parent, :class=>self
        one_to_many :children, :key=>:parent_id, :class=>self, :order=>:created_at.desc
        one_to_many :postings
        many_to_many :topics, :join_table=>:postings, :left_key=>:post_id, :right_key=>:topic_id, :class =>'Journ::Models::Topic'
        def self.all_unclassified
            Post.filter("(id NOT IN ?) AND (parent_id = 0)", Posting.select(:post_id).group(:post_id)).order(:created_at.desc)
        end
        def Post.year_month
            return [] if self.count.zero?
            y1, m1, d1=Post.min(:created_at).split('-')[0..2].map{|i| i.to_i}
            y2, m2, d2=Post.max(:created_at).split('-')[0..2].map{|i| i.to_i}
            store={}
            min_date = Date.new(y1,m1,1)
            max_date = Date.new(y2,m2,1)
            c = 0
            while min_date>>c <= max_date
                dt = (min_date >> c)
                (store[dt.year]||=[])<<(dt.month)
                c += 1
            end
            store
        end
        def title
            post.split(/\n/).first
        end
        def path_depth
            self.path.split('/').size-1
        end
        def topic_names
            topics.map(&:topic).sort.join(', ')
        end
        def post_short(maxlen=140)
            psize = post.size
            post[0..maxlen] + (psize < maxlen ? '' : '...')
        end
        def root
            Post.find(:id=>path.split('/').first.to_i, :parent_id=>0) || self # '00001'.to_i = 1
        end
        def root_and_descendants
            [root] + root.descendants.all
        end
        def descendants
            Post.filter("path like '#{self.path}/%'").order(:path)
        end
        def ancestors
            Post.filter("('#{self.path}' like path||'%') AND (id != #{self.id})").order(:path)
        end
        def self_and_siblings
            Post.filter(:parent_id => self.parent_id).order(:path)
        end
        def siblings
            Post.filter("(parent_id = #{self.parent_id}) AND (id != #{self.id})").order(:created_at)
        end
        def valid_parents
            Post.filter(:id=>([root.id, root.descendants.map(&:id)].flatten - [self.id, self.descendants.map(&:id)].flatten)).order(:id)
        end
        def next_post
            # opt: select id from posts where id > #{self[:id]} order id limit 1
            #  --but stay w/in the thread
            idxs = self.root_and_descendants.map{|p| p[:id]}
            idx=idxs.index(self[:id]).succ
            idx = -1 if idx > idxs.size
            Post[idxs[idx]]
        end
        def prev_post
            # opt: select id from posts where id < #{self[:id]} order id limit 1
            idxs = self.root_and_descendants.map{|p| p[:id]}
            idx=idxs.index(self[:id]).pred
            idx = 0 if idx < 1
            Post[idxs[idx]]
        end
        #======================
        def tag_with_topics
            ::Camping::DB.transaction do
                _topic_names_.each do |t|
                    a_topic=Topic.find_or_create(:topic=>t)
                    add_posting(:topic=>a_topic) unless is_tagged?(a_topic)
                end
            end
        end

        def after_save
            pp __method__
            tag_with_topics()
            refresh_postings!
            super
        end

        private # helper methods

        def refresh_postings!
            new_postings_ids = Topic.filter(:topic=>_topic_names_).map(&:id)
            current_postings_ids = postings.map(&:topic_id)
            p r_ids = (current_postings_ids | new_postings_ids) - new_postings_ids
            postings_dataset.filter(:topic_id=>r_ids).delete
        end
        def is_tagged?(topic)
            postings.map{|t| t.topic_id}.include?(topic.id)
        end
        def _topic_names_
            # prepares safe settings for topic names
            return [] if post_topics.nil?
            post_topics.split(/,/).map{|t| t.strip.downcase}
        end
        #======================

        def after_create
            p self.path=build_path(self)
            self.save
            super
        end
        def before_destroy
            p [__method__, :before, self.path]
            repath_children(self.parent) # children moves up the chain
            p [__method__, :after , self.path]
            super
        end
        def before_update
            p [__method__, :before, self.path]
            self.path=build_path(self)
            p [__method__, :after , self.path]
            super
        end
        def after_update
            # search all children
            # repath_children(self) if parent changed. ie moved to another branch
            repath_children(self)
            super
        end

        private

        def repath_children(post)
            #recursive method to repath all children, next level children ... downwards
            parent_path=post.path
            post.children.map do |c|
                c.update :path=>build_path(c)
                repath_children(c) unless c.children.empty?
            end
        end
        def build_path(post)
            pad_id = SPADDING % post.id
            parent_path = post.parent.try(:path)
            [parent_path, pad_id].compact.join('/')
        end
    end
    class Posting < Sequel::Model
        many_to_one :topic
        many_to_one :post
    end
    class Relationship < Sequel::Model
        many_to_one :topic
        many_to_one :following, :key=>:following_id, :class=>:Topic
    end
end
