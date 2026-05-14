import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";

export default class TopReplies extends Component {
  @service siteSettings;

  avatarUrl(avatarTemplate) {
    if (!avatarTemplate) {
      return null;
    }
    return avatarTemplate.replace("{size}", "40");
  }

  @action
  connectToCard(tdElement) {
    const ourRow = tdElement.closest("tr");
    if (!ourRow) {
      return;
    }

    let prev = ourRow.previousElementSibling;
    while (prev && !prev.matches("tr.topic-list-item")) {
      prev = prev.previousElementSibling;
    }
    if (!prev) {
      return;
    }

    prev.classList.add("has-top-replies");

    const card = prev.querySelector(".custom-topic-layout");
    if (card) {
      card.style.setProperty("border-bottom-left-radius", "0", "important");
      card.style.setProperty("border-bottom-right-radius", "0", "important");
      card.style.setProperty("border-bottom-color", "transparent", "important");
    }
  }

  <template>
    {{#if this.siteSettings.discourse_top_replies_enabled}}
      {{#if @outletArgs.topic.top_liked_replies.length}}
        <tr class="top-replies-row" style="display: block; margin-top: -1em">
          <td
            class="top-replies-cell"
            colspan="7"
            {{didInsert this.connectToCard}}
          >
            <div class="top-replies-list">
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
          </td>
        </tr>
      {{/if}}
    {{/if}}
  </template>
}
