# frozen_string_literal: true

# name: discourse-top-replies
# about: Shows the first 5 replies under each topic in the topic list
# version: 0.3.4
# authors: Timo
# url: https://github.com/nocactus/discourse-top-replies

enabled_site_setting :discourse_top_replies_enabled

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

    topics.each do |topic|
      topic.instance_variable_set(:@top_liked_replies, replies_by_topic[topic.id] || [])
    end
  end

  add_to_serializer(:topic_list_item, :top_liked_replies) do
    replies = object.instance_variable_get(:@top_liked_replies) || []
    replies.map do |post|
      {
        post_number: post.post_number,
        like_count: post.like_count,
        excerpt: post.excerpt(200, strip_links: true, strip_images: true),
        username: post.user&.username,
        avatar_template: post.user&.avatar_template,
        reply_to_post_number: post.reply_to_post_number,
      }
    end
  end
end
