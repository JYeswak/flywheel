import type { MetaRecord } from 'nextra'

// flywheel-ti46c (Phase 2 of 38u3d): audience-persona + Diátaxis IA seed.
//
// Audience personas (4):
//   - orch:     orchestrator pane (flywheel:1); reads doctrine + dispatch contracts
//   - worker:   worker pane (flywheel:0.N); reads tick + callback contracts
//   - Joshua:   operator/decision-maker; reads mission + paradigm anchors
//   - operator: external operator running flywheel against client repos
//
// Diátaxis quadrants:
//   - tutorials: learning-oriented (Tutorials)
//   - guides:    task-oriented (How-to Guides)
//   - reference: information-oriented (Reference)
//   - concepts:  understanding-oriented (Explanation)

export default {
  index: {
    type: 'page',
    display: 'hidden'
  },
  tutorials: {
    type: 'page',
    title: 'Tutorials',
    theme: {
      breadcrumb: true,
      collapsed: false
    }
  },
  guides: {
    type: 'page',
    title: 'How-to Guides',
    theme: {
      breadcrumb: true,
      collapsed: false
    }
  },
  reference: {
    type: 'page',
    title: 'Reference',
    theme: {
      breadcrumb: true,
      collapsed: false
    }
  },
  concepts: {
    type: 'page',
    title: 'Concepts',
    theme: {
      breadcrumb: true,
      collapsed: false
    }
  }
} satisfies MetaRecord
