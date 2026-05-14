import Component from "@glimmer/component";
import { service } from "@ember/service";

export default class TopReplies extends Component {
  @service siteSettings;

  <template>
    {{#if this.siteSettings.discourse_top_replies_enabled}}
      {{#if @outletArgs.topic.top_liked_replies.length}}
        <td class="top-replies-cell" colspan="7">
          <div class="top-replies-list">
            {{#each @outletArgs.topic.top_liked_replies as |reply|}}
              <a
                href="/t/{{@outletArgs.topic.slug}}/{{@outletArgs.topic.id}}/{{reply.post_number}}"
                class="top-reply-item"
              >
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
    {{/if}}
  </template>
}
