import Component from "@glimmer/component";

export default class TopReplies extends Component {
  get topic() {
    return this.args.outletArgs.topic;
  }

  get topReplies() {
    return this.topic?.top_liked_replies || [];
  }

  postUrl(reply) {
    return `/t/${this.topic.slug}/${this.topic.id}/${reply.post_number}`;
  }

  <template>
    {{#if this.topReplies.length}}
      <td class="top-replies-cell" colspan="7">
        <div class="top-replies-list">
          {{#each this.topReplies as |reply|}}
            <a href={{this.postUrl reply}} class="top-reply-item">
              <span class="top-reply-username">@{{reply.username}}</span>
              <span class="top-reply-excerpt">{{reply.excerpt}}</span>
              {{#if reply.like_count}}
                <span class="top-reply-likes">♥ {{reply.like_count}}</span>
              {{/if}}
            </a>
          {{/each}}
        </div>
      </td>
    {{/if}}
  </template>
}
