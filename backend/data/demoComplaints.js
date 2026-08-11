/**
 * Demo Complaints — Realistic scenarios designed to showcase AI capabilities
 * Each complaint is crafted to demonstrate a specific AI feature.
 */

const now = new Date();
const hoursAgo = (h) => new Date(now.getTime() - h * 3600000).toISOString();

const demoComplaints = [
  // Scenario A: Large pothole near school — HIGH priority, safety risk
  {
    id: "CP-2026-10001",
    title: "Dangerous large pothole near Government School",
    description: "There is a massive pothole on the main road outside the Government Primary School near Chunkankadai Junction. Several children have nearly fallen into it. A motorcycle accident happened yesterday because of this. The hole is about 3 feet wide and growing. Immediate action needed before more accidents occur.",
    location: { lat: 8.2000, lng: 77.3833, address: "Chunkankadai Junction, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(6),
    resolution: null,
    reopenCount: 0
  },

  // Scenario B: Garbage near hospital — health hazard
  {
    id: "CP-2026-10002",
    title: "Garbage pile overflowing near health centre",
    description: "A huge pile of garbage has been accumulating near the Chunkankadai health centre for over a week. The smell is unbearable and is attracting stray dogs and rats. This is a serious health hazard for patients and visitors. Staff have complained multiple times.",
    location: { lat: 8.2026, lng: 77.3854, address: "Near Chunkankadai Health Centre, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(48),
    resolution: null,
    reopenCount: 0
  },

  // Scenario C: Water leak — related reports cluster
  {
    id: "CP-2026-10003",
    title: "Major water pipe burst flooding the street",
    description: "A large water main has burst on Chunkankadai–Aloor Road causing severe flooding. Water has been flowing for 3 hours now. The entire street is submerged and residents cannot leave their homes. Electricity poles in the flooded area pose electrocution risk.",
    location: { lat: 8.1985, lng: 77.3808, address: "Chunkankadai–Aloor Road, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(3),
    resolution: null,
    reopenCount: 0
  },

  // Scenario D: Electrical hazard — immediate danger
  {
    id: "CP-2026-10004",
    title: "Exposed live electrical wires hanging over playground",
    description: "Live electrical wires are hanging dangerously low over the public playground in Chunkankadai. The insulation has completely worn off and sparks are visible. Children play here every evening. This is an extreme electrocution risk. Multiple residents have reported it but received no response.",
    location: { lat: 8.1968, lng: 77.3865, address: "Public Playground, Chunkankadai, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(1),
    resolution: null,
    reopenCount: 0
  },

  // Scenario E: Similar to A — duplicate/cluster detection
  {
    id: "CP-2026-10005",
    title: "Deep road hole causing accidents near school area",
    description: "There is a deep dangerous hole in the road near the school at Chunkankadai Junction. Two accidents happened this week. The pit is very large and filled with water so drivers cannot see it. Very risky for school children crossing the road.",
    location: { lat: 8.2002, lng: 77.3835, address: "Chunkankadai Junction School Zone, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(4),
    resolution: null,
    reopenCount: 0
  },

  // Scenario F: Resolved with vague description — low resolution quality
  {
    id: "CP-2026-10006",
    title: "Broken streetlight on residential road",
    description: "The streetlight outside house #42 on Sree Ayyappa College Road has been broken for 2 weeks. The entire stretch of road is completely dark at night. Residents feel unsafe walking after 7 PM. There have been reports of theft in the dark area.",
    location: { lat: 8.2042, lng: 77.3817, address: "Sree Ayyappa College Road, Chunkankadai" },
    photoUrl: "",
    status: "awaiting_verification",
    createdAt: hoursAgo(72),
    resolution: { description: "Fixed.", resolvedAt: hoursAgo(12) },
    reopenCount: 0
  },

  // Scenario G: Department trust issue — reopened complaint
  {
    id: "CP-2026-10007",
    title: "Overflowing sewage drain causing health issues",
    description: "The main sewage drain along Chunkankadai Pond Road has been overflowing for 3 days. Raw sewage is flooding into residential areas. Children have fallen sick due to contamination. The drain was supposedly fixed last month but the problem returned within a week.",
    location: { lat: 8.2010, lng: 77.3788, address: "Chunkankadai Pond Road, Kanyakumari" },
    photoUrl: "",
    status: "reopened",
    createdAt: hoursAgo(96),
    resolution: { description: "Drain cleaned and blockage removed. Water flow restored to normal.", resolvedAt: hoursAgo(48) },
    reopenCount: 2
  },

  // Scenario H: Another similar water complaint — cluster
  {
    id: "CP-2026-10008",
    title: "Water supply pipe leaking on Aloor Road",
    description: "A water pipe is leaking badly on Chunkankadai–Aloor Road. The road is getting damaged from water erosion. This has been going on for days and nobody has come to fix it.",
    location: { lat: 8.1987, lng: 77.3810, address: "Chunkankadai–Aloor Road, Kanyakumari" },
    photoUrl: "",
    status: "assigned",
    createdAt: hoursAgo(12),
    resolution: null,
    reopenCount: 0
  }
];

module.exports = demoComplaints;
