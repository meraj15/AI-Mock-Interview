// ── Voice Interview Room States ──────────────────────────────────────────────

enum InterviewPhase {
  loading,   // Initial session setup / planning
  speaking,  // AI interviewer is speaking question & streaming text
  listening, // AI is waiting for candidate to start speaking
  recording, // Candidate is actively recording response
  answered,  // Recording stopped; user reviews & edits answer before submitting
  thinking,  // Answer received, AI is processing / generating next question
  done,      // Session finished
}
