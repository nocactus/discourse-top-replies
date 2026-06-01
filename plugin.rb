# frozen_string_literal: true

# name: discourse-top-replies
# about: Shows the first 5 replies under each topic in the topic list
# version: 0.4.7
# authors: Timo
# url: https://github.com/nocactus/discourse-top-replies

enabled_site_setting :discourse_top_replies_enabled

register_asset "stylesheets/common/top-replies.scss"

after_initialize do
  TopicList.on_preload do |topics, topic_list|
    next if topics.empty?
    next unless SiteSetting.discourse_top_replies_enabled

    topic_ids = topics.map(&:id)

    # Load all replies for these topics, ordered chronologically
    all_posts =
      Post
        .where(topic_id: topic_ids)
        .where("post_number > 1")
        .where(deleted_at: nil)
        .where(post_type: Post.types[:regular])
        .order(post_number: :asc)
        .select(:id, :topic_id, :post_number, :like_count, :cooked, :user_id,
                :reply_to_post_number)
        .includes(:user)

    # Per topic: take first 5 direct replies; for nested replies use only the first
    replies_by_topic =
      all_posts
        .group_by(&:topic_id)
        .transform_values do |posts|
          seen_nested_parent = {}
          result = []
          posts.each do |post|
            nested = post.reply_to_post_number.present? && post.reply_to_post_number > 1
            if nested
              parent = post.reply_to_post_number
              next if seen_nested_parent[parent]
              seen_nested_parent[parent] = true
            end
            result << post
            break if result.size >= 5
          end
          result
        end

    # Load first posts for like functionality
    first_posts = Post
      .where(topic_id: topic_ids, post_number: 1)
      .select(:id, :topic_id, :like_count)
    first_posts_by_topic = first_posts.index_by(&:topic_id)

    # Batch-load current user's likes for first posts
    current_user = topic_list.current_user
    liked_ids = Set.new
    if current_user && first_posts.any?
      liked_ids = PostAction
        .where(
          post_id: first_posts.map(&:id),
          user_id: current_user.id,
          post_action_type_id: PostActionType.types[:like]
        )
        .where(deleted_at: nil)
        .pluck(:post_id)
        .to_set
    end

    topics.each do |topic|
      topic.instance_variable_set(:@top_liked_replies, replies_by_topic[topic.id] || [])
      first_post = first_posts_by_topic[topic.id]
      topic.instance_variable_set(:@first_post_id, first_post&.id)
      topic.instance_variable_set(:@first_post_like_count, first_post&.like_count || 0)
      topic.instance_variable_set(:@first_post_user_liked, liked_ids.include?(first_post&.id))
    end
  end

  add_to_serializer(:topic_list_item, :top_liked_replies) do
    replies = object.instance_variable_get(:@top_liked_replies) || []
    replies.map do |post|
      cooked = post.cooked.gsub(/<img\b[^>]*\bclass="[^"]*emoji[^"]*"[^>]*\/?>/) do |tag|
        name = tag.match(/\btitle=":([\w+-]+):"/i)&.captures&.first
        if name
          Emoji.lookup_unicode(name) || ":#{name}:"
        else
          tag.match(/\balt="([^"]+)"/)&.captures&.first.to_s
        end
      end
      {
        post_number: post.post_number,
        like_count: post.like_count,
        excerpt: PrettyText.excerpt(cooked, 200, strip_links: true, strip_images: true),
        username: post.user&.username,
        avatar_template: post.user&.avatar_template,
        reply_to_post_number: post.reply_to_post_number,
      }
    end
  end

  add_to_serializer(:topic_list_item, :first_post_id) do
    object.instance_variable_get(:@first_post_id)
  end

  add_to_serializer(:topic_list_item, :first_post_like_count) do
    object.instance_variable_get(:@first_post_like_count) || 0
  end

  add_to_serializer(:topic_list_item, :first_post_user_liked) do
    object.instance_variable_get(:@first_post_user_liked) || false
  end
end
