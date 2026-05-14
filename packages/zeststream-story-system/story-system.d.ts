export type ProofState = "proven" | "blocked" | "skipped-with-reason" | "private"

export interface StorySystemPackage {
  schema_version: "zeststream.story_system_package.v0"
  status: string
  source_message_schema: "zeststream.repo_story_message.v0"
  source_dossier_schema: "zeststream.repo_story_dossier.v0"
  source_frontend_schema: "zeststream.repo_frontend_story.v0"
  core_offer: string
  primary_cta: string
  secondary_cta: string
  audience_truths: string[]
  owner_language_bank: {
    lead_with: string[]
    replace: Array<{ weak: string; strong: string }>
    proof_phrases: string[]
  }
  story_arc_stages: string[]
  proof_states: ProofState[]
  visual_primitives: string[]
  page_blueprint_sections: string[]
  owner_objection_count: number
  voice_rules: string[]
  blocked_phrases: string[]
  nextjs_targets: string[]
  visual_quality_gates: string[]
  required_css_tokens: string[]
}

export declare const storySystem: StorySystemPackage
export declare const proofStates: ProofState[]
export declare const visualPrimitives: string[]
export declare const pageBlueprintSections: string[]
export declare const requiredCssTokens: string[]
export declare const blockedPhrases: string[]

export declare function assertStorySystemContract(value?: StorySystemPackage): StorySystemPackage

export default storySystem
