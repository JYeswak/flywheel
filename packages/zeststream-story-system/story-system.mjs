import storySystemJson from "./story-system.json" with { type: "json" }

export const storySystem = storySystemJson
export const proofStates = storySystem.proof_states
export const visualPrimitives = storySystem.visual_primitives
export const pageBlueprintSections = storySystem.page_blueprint_sections
export const requiredCssTokens = storySystem.required_css_tokens
export const blockedPhrases = storySystem.blocked_phrases

export function assertStorySystemContract(value = storySystem) {
  if (value.schema_version !== "zeststream.story_system_package.v0") {
    throw new Error("Invalid ZestStream story-system schema")
  }
  if (value.primary_cta !== "Map my workflow") {
    throw new Error("Invalid ZestStream story-system CTA")
  }
  if (!value.proof_states.includes("blocked")) {
    throw new Error("ZestStream story-system must expose blocked proof state")
  }
  return value
}

export default storySystem
