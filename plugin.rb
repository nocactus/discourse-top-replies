# frozen_string_literal: true

# name: discourse-top-replies
# about: Shows the 3 most liked replies under each topic in the topic list
# version: 0.1.0
# authors: Timo
# url: https://github.com/nocactus/discourse-top-replies

after_initialize do
  TopicList.on_preload do |topics, topic_list|
    next if topics.empty?

    topic_ids = topics.map(&:id)

    posts =
      Post
        .where(topic_id: topic_ids)
        .where("post_number > 1")
        .where(deleted_at: nil)
        .where(post_type: Post.types[:regular])
        .order(like_count: :desc, post_number: :asc)
        .select(:id, :topic_id, :post_number, :like_count, :cooked, :user_id)
        .includes(:user)

    replies_by_topic = posts.group_by(&:topic_id).transform_values { |p| p.take(3) }

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
        excerpt: post.excerpt(150, strip_links: true, strip_images: true),
        username: post.user&.username,
      }
    end
  end
end
