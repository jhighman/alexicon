# Renders a `ValueWorksheet` as something a person can sit down with.
#
# Deliberately austere. It shows two statements and asks two questions, and it
# shows nothing else — no category, no verdict, no confidence, and above all no
# machine reading of the pair. Every one of those would tell the reader what the
# system already thinks, and a reader who has been told that is measuring their
# agreement rather than their judgement.
#
# The instructions say plainly that most pairs have no conflict in them and that
# "no" is the expected answer. That is not encouragement to be lazy: the whole
# failure being investigated is a judge that named a commitment on 68% of pairs
# with no relation at all, and a worksheet that made "no" feel like a failure to
# engage would reproduce exactly that.
class ValueWorksheetReport
  def self.render(sheet, values: FrameworkValue.vocabulary) = new(sheet, values: values).render

  def initialize(sheet, values:)
    @sheet = sheet
    @values = values.to_a
  end

  def render = MarkdownReflow.call([ header, vocabulary, *items, footer ].join("\n\n"))

  private

  attr_reader :sheet, :values

  def header
    <<~MD.strip
      # Value worksheet — document #{sheet.document.id}

      **#{sheet.items.size} pairs · worksheet #{sheet.assertion.id} · seed #{sheet.seed}**

      Two statements per item. For each one, two questions:

      1. **Is there a conflict here at all?** Does the move from the first to the
         second hold on to something at the cost of something else?
      2. **If yes**, what is put first, and what is set aside?

      > **Most pairs have no conflict in them, and "no" is the expected answer.**
      > A statement that simply goes further than the one before it, an aside, a
      > change of subject, a turn of phrase — none of those trade one commitment
      > against another. Naming a pair for them would be inventing a dilemma that
      > is not there, and that is the exact failure this sheet exists to measure.
      >
      > **Some of these pairs are not arguments.** They are two sentences from
      > different parts of the document with no relation to each other, mixed in
      > deliberately and not marked. If you find yourself able to name a conflict
      > in every item, that is the finding.
      >
      > Leave an item blank rather than guessing. A blank is dropped from the
      > count; a guess is not.

      Nothing here shows what the system concluded about any pair. That is on
      purpose — you are not checking its work, you are doing the task it could
      not.
    MD
  end

  def vocabulary
    rows = values.map { "| #{it.name} | #{it.definition} | #{it.subordinates} |" }

    <<~MD.strip
      ## The values, if you want them

      Use these words or your own. The list is the framework's and is not
      exhaustive — if what is being protected is not here, write it.

      | Value | What it protects | What it puts aside |
      |---|---|---|
      #{rows.join("\n")}
    MD
  end

  def items = sheet.items.map { item(it) }

  def item(entry)
    <<~MD.strip
      ---

      ### #{entry.number}.

      > #{entry.first}

      > #{entry.second}

      | | |
      |---|---|
      | Conflict here? | ☐ yes ☐ no |
      | If yes, puts first | |
      | If yes, sets aside | |
    MD
  end

  def footer
    <<~MD.strip
      ---

      ## When you are done

      Score it with the recorded key, which was written before you answered:

      ```
      rake 'alexicon:worksheet_score[#{sheet.assertion.id},"1y 2n 3y …"]'
      ```

      That reports how often you found a conflict in a real step against how
      often you found one in a pair that was never an argument, as a difference
      in standard errors. The same statistic scored the three machine attempts at
      3.08, 0.29 and 0.54 — so your figure sits directly beside theirs.

      **What it decides.** If you discriminate well, the question has ground truth
      in the text and the machine is what failed: the value layer is a model
      problem and worth another attempt. If you cannot discriminate either, the
      recorded diagnosis holds — the question is ungrounded in a found text — and
      the layer should be retired. That would be the first evidence for retiring
      it that is not itself a model's failure.
    MD
  end
end
