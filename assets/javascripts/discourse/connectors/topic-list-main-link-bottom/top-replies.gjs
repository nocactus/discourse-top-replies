import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class TopReplies extends Component {
  @service siteSettings;

  avatarUrl(avatarTemplate) {
    if (!avatarTemplate) {
      return null;
    }
    return avatarTemplate.replace("{size}", "40");
  }

  <template>
    {{#if this.siteSettings.discourse_top_replies_enabled}}
      {{#if @outletArgs.topic.top_liked_replies.length}}
        <div class="top-replies">
          {{#each @outletArgs.topic.top_liked_replies as |reply|}}
            <a
              href="/t/{{@outletArgs.topic.slug}}/{{@outletArgs.topic.id}}/{{reply.post_number}}"
              class="top-reply-item"
            >
              {{#if reply.avatar_template}}
                <img
                  src={{this.avatarUrl reply.avatar_template}}
                  class="top-reply-avatar"
                  alt={{reply.username}}
                />
              {{/if}}
              <div class="top-reply-content">
                <span class="top-reply-username">{{reply.username}}</span>
                <span class="top-reply-excerpt">{{reply.excerpt}}</span>
              </div>
              {{#if reply.like_count}}
                <span class="top-reply-likes">♥ {{reply.like_count}}</span>
              {{/if}}
            </a>
          {{/each}}
        </div>
      {{/if}}
    {{/if}}
  </template>
}
