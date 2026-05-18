import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import didInsert from "@ember/render-modifiers/modifiers/did-insert";

export default class TopReplies extends Component {
  @service siteSettings;
  @service currentUser;

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

    // Inject like button into the bottom bar of the topic card
    const topic = this.args.outletArgs.topic;
    const bottomBar = prev.querySelector(".custom-topic-layout_bottom-bar");
    if (bottomBar && topic.first_post_id) {
      let liked = topic.first_post_user_liked || false;
      let count = topic.first_post_like_count || 0;

      const btn = document.createElement("span");
      btn.className = "top-replies-like-btn" + (liked ? " is-liked" : "");
      btn.setAttribute("role", "button");
      btn.setAttribute("tabindex", "0");
      btn.innerHTML = `♥ ${count}`;

      btn.addEventListener("click", async (e) => {
        e.preventDefault();
        e.stopPropagation();

        if (!this.currentUser) {
          return;
        }

        const csrfToken = document
          .querySelector('meta[name="csrf-token"]')
          ?.getAttribute("content");
        const wasLiked = liked;

        liked = !wasLiked;
        count = count + (wasLiked ? -1 : 1);
        btn.innerHTML = `♥ ${count}`;
        btn.classList.toggle("is-liked", liked);

        try {
          let resp;
          if (wasLiked) {
            resp = await fetch(
              `/post_actions/${topic.first_post_id}?post_action_type_id=2&flag_topic=false`,
              {
                method: "DELETE",
                headers: { "X-CSRF-Token": csrfToken },
              }
            );
          } else {
            resp = await fetch("/post_actions", {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": csrfToken,
              },
              body: JSON.stringify({
                id: topic.first_post_id,
                post_action_type_id: 2,
                flag_topic: false,
              }),
            });
          }
          if (!resp.ok) {
            throw new Error();
          }
        } catch {
          liked = wasLiked;
          count = count + (wasLiked ? 1 : -1);
          btn.innerHTML = `♥ ${count}`;
          btn.classList.toggle("is-liked", liked);
        }
      });

      bottomBar.appendChild(btn);
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
                <div
                  class="top-reply-item {{if reply.reply_to_post_number "top-reply-nested"}}"
                  style="display:flex;flex-direction:row;align-items:flex-start;gap:8px"
                >
                  {{#if reply.avatar_template}}
                    <img
                      src={{this.avatarUrl reply.avatar_template}}
                      class="top-reply-avatar"
                      alt={{reply.username}}
                      style="width:25px;height:25px;max-width:25px;border-radius:100%;flex-shrink:0;object-fit:cover;margin-top:2px"
                    />
                  {{/if}}
                  <div class="top-reply-content">
                    <a
                      href="/t/{{@outletArgs.topic.slug}}/{{@outletArgs.topic.id}}/{{reply.post_number}}"
                      class="top-reply-link"
                      style="color:var(--primary);text-decoration:none"
                    >
                      <span class="top-reply-username" style="color:var(--primary)">
                        {{#if reply.reply_to_post_number}}↩ {{/if}}{{reply.username}}
                      </span>
                      <span class="top-reply-excerpt" style="color:var(--primary-high)">{{reply.excerpt}}</span>
                    </a>
                    <div class="top-reply-actions">
                      <a
                        href="/t/{{@outletArgs.topic.slug}}/{{@outletArgs.topic.id}}/{{reply.post_number}}"
                        class="top-reply-reply-btn"
                        style="color:var(--primary-medium);text-decoration:none;font-size:0.78em;font-weight:600"
                      >Reply</a>
                    </div>
                  </div>
                  {{#if reply.like_count}}
                    <span class="top-reply-likes">♥ {{reply.like_count}}</span>
                  {{/if}}
                </div>
              {{/each}}
            </div>
          </td>
        </tr>
      {{/if}}
    {{/if}}
  </template>
}
