Synthetic C# fixture, in the style of this project's real
`code-csharp-*` tasks. Not read by any script — kept for traceability.
Deliberately reuses `review-concurrency`'s bug shape (a plain Dictionary
behind a static field) as a false-positive bait, with a stated
single-worker guarantee that makes it genuinely safe.
