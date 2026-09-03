---
name: write-responsibly
description: "Edit or draft prose that respects the reader's time. Cuts AI slop (hedge stacks, filler, inflated words, throat-clearing, em-dashes, semicolons) while keeping the writer's voice and register. Use when the user wants any prose tightened, clarified, or humanized: an email, README, blog post, PR description, announcement, doc, or message ('make this clearer', 'tighten this up', 'this sounds like AI', 'remove the slop', 'deslop this'). Also use when the user wants help writing new prose meant to be read by people. For making code docs and comments timeless, see timeless-docs. This skill governs how any prose reads."
---

# Write Responsibly

## The reader's contract

1. **Use a stranger's time as if it cost them something.** It does.
2. **Every sentence informs or advances the point.** A sentence that does neither is decoration. Cut it.
3. **Start as close to the end as possible.** The first paragraph of most drafts is the wind-up, not the pitch. Delete it and check whether anything is missing. Usually nothing is.
4. **Write to one person.** Prose aimed at everyone hedges everything and lands with no one. Name the reader, then edit for that reader alone.
5. **No suspense.** The reader should know what, where, and why so early they could finish the piece themselves. Withholding is for thrillers.

## The words

- **Short, plain words.** Some words call up a picture at once. Others must be translated first. Use the first kind: *utilize* → use, *facilitate* → help, *precipitation* → rain, *commence* → start, *endeavor* → try, *approximately* → about.
- **Familiar combinations.** "The biota exhibited a one hundred percent mortality response" means "all the fish died." Write the second one.
- **Jargon must pay rent.** A term of art the reader's field actually uses stays. Insider shorthand an outsider trips on gets replaced, or glossed the first time it appears.
- **Start where the reader is.** You have forgotten what it is like not to know what you know. Assume less, and bring the reader along.

## The sentences

- **Short sentences, short paragraphs.** One idea per sentence. One step of the argument per paragraph. A long sentence is fine when it is long on purpose, not because two thoughts got glued together.
- **No em-dashes, no semicolons.** Both mark a sentence that wants to be two. Split it. If the halves need a link, write the link out: "so", "but", "then", "because", "which means".
- **Keep the connective tissue.** Sentences must show how they relate. Cutting every "so", "but", "because", and "for example" leaves a list of facts where the reader had an argument. The goal is a text that reads faster, not a text that reads as notes.

## Slop tells

| Tell | Move |
|------|------|
| **Hedge stack**: "may potentially", "it's worth noting that", "arguably", "somewhat" | Keep one hedge where the uncertainty is real and delete the rest. A hedge on everything protects nothing. |
| **Empty intensifiers**: "very", "truly", "incredibly", "significantly" | Delete. If the emphasis matters, buy it with a stronger noun or verb. |
| **Inflated vocabulary**: delve, robust, comprehensive, crucial, seamless, leverage, landscape, foster, showcase, underscore | Swap for the plain word. |
| **The triad tic**: "fast, reliable, and scalable" in every other sentence | Keep the one claim that is true and load-bearing. Threes are rhythm pretending to be content. |
| **"It's not just X, it's Y"** and "not only… but also" | Say Y. |
| **Throat-clearing**: "In today's fast-paced world…", "It's important to note that…", "Let's dive in" | Delete. Start at the point. For a cold reader, tighten to one orienting sentence instead. |
| **The recap ending**: "In conclusion", a final paragraph restating the piece | End when the last new thing has been said. A one-line closing beat may stay where the register expects one. A paragraph restating the piece may not. |
| **Em-dashes and semicolons** | Split the sentence, or join the halves with a written-out link ("so", "but", "because"). A comma or colon is fine where it reads naturally. |
| **Formatting as emphasis**: bold doing the work words should do | Let word choice and sentence order carry it. |

## The two laws of editing

1. **Cut and swap. Never restructure.** Deleting and word-swapping are register-safe: an email stays an email, an essay stays an essay. Adding headings, bullets, topic sentences, or a bottom-line-up-front changes what kind of text it is, and that is the writer's call, not the editor's. Structural problems get flagged, never fixed silently. Deleting a wind-up opening is a cut, not a restructure.
2. **Sound like the writer.** Edit words, not personality. Playful stays playful, blunt stays blunt, formal stays formal. If a run of edits leaves text anyone could have written, back up. Voice-flattening is the slop you came to remove.

## Rewrite examples

```
❌ It's worth noting that this approach may potentially introduce some performance considerations.
✅ This is slower.

❌ We leveraged a comprehensive caching strategy to significantly enhance responsiveness.
✅ We cache aggressively, so pages load fast.

❌ In today's fast-paced development landscape, testing is more crucial than ever.
✅ (deleted, the piece starts at the next sentence)

❌ This isn't just a bug fix — it's a fundamental rethinking of how we handle state.
✅ This changes how we handle state.

❌ The migration is safe — it runs in a transaction; nothing gets dropped.
✅ The migration is safe because it runs in a transaction and drops nothing.

❌ The system is designed to be robust, scalable, and maintainable.
✅ The system survives a node failure without dropping writes.
   (replace the triad with the one concrete claim you can back)
```

Voice survives the edit:

```
❌ Honestly, this API is somewhat of a dumpster fire, and it may potentially be worth considering a rewrite at some point.
✅ Honestly, this API is a dumpster fire. Worth a rewrite.
```

## Two modes

### Edit mode: text that exists

The default when the user hands over text or points at a file. Run the workflow below on it.

### Write mode: text being born

When drafting prose for the user (a PR description, an email, an announcement, a README section, a post), the contract applies while writing. Know the point before the first sentence. Outline first, write second, even if the outline lives in your head. Then run the edit-mode workflow on your own draft before showing it.

## Workflow (edit mode)

1. **Read it whole.** Identify the register (email, README, announcement, essay, message) and the one reader it is for. Every later choice is measured against those two. The register also sets cut depth. A **warm reader** already has context (email, PR description, review comment, chat message), so cut wind-up and closings outright. A **cold reader** arrives from a link with nothing (blog post, announcement, essay), so keep one sentence of orientation up front and allow a single closing beat.
2. **Cut pass.** Remove sentences that neither inform nor advance, and every slop tell from the table: throat-clearing, hedge stacks, recaps, intensifiers.
3. **Swap pass.** Plain words, familiar combinations, jargon that stopped paying rent. Em-dashes and semicolons become periods or written-out links.
4. **Check the opening.** Does it start as close to the end as possible? If the first paragraph is wind-up, cut it. For a cold reader, compress it to the single sentence that orients.
5. **Read it back.** Where you stumble or drift, the reader will too. A stretch where every sentence has the same length and shape reads as nobody-home, so cut unevenly to restore pulse. Where two sentences sit side by side with no link, the reader has to guess how they relate. Write the link.
6. **Verify.** Meaning intact. Hedges with real uncertainty kept. Voice intact: the writer would still recognize themselves.

## Guardrails

- **Meaning first.** Never trade a fact for brevity. A hedge that carries real uncertainty stays, because deleting it manufactures confidence the writer never had.
- **Hands off** quoted text, code, commands, error messages, legal language, API names, and anything cited verbatim.
- **Flag, don't rebuild.** Wrong order, missing context, bullets where a connected argument should be. Report these to the writer instead of silently restructuring.
- **Deliberate style is not slop.** Repetition, rhythm, a long sentence built long on purpose. In creative or literary text, edit with a lighter hand and ask when unsure.
- **A tight text stays untouched.** If there is little to cut, say so. Do not manufacture edits to justify the pass.

## Neighbors

- **timeless-docs** decides *what* code docs and comments say (present state, no history). This skill governs how any prose *reads*. They compose, so run timeless-docs first on code documentation.
- **exec-summary** produces a summary of something else. This skill edits the text itself.

## Output

- The rewritten text.
- A short list of what changed, grouped by tell (hedges cut, words swapped, sentences deleted), enough for the writer to veto any single edit.
- Flags: structural issues left alone, claims that looked wrong, edits you were unsure about.
