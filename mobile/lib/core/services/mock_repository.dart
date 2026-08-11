import '../models/complaint.dart';
import '../models/user.dart';
import '../models/comment.dart';
import '../models/notification.dart';
import '../models/timeline_event.dart';

class MockRepository {
  static final MockRepository _instance = MockRepository._internal();
  factory MockRepository() => _instance;
  MockRepository._internal() {
    _initData();
  }

  late List<User> users;
  late List<Complaint> complaints;
  late List<UserNotification> notifications;

  void _initData() {
    // 1. Mock Users
    users = [
      User(
        id: 'admin_roads',
        name: 'Rajesh Kumar (Roads Admin)',
        email: 'roads_admin@gov.in',
        phone: '+91 98765 00001',
        role: 'ADMIN',
        departmentId: 'ROADS_HIGHWAYS',
      ),
      User(
        id: 'admin_water',
        name: 'Anil Sharma (Water Admin)',
        email: 'water_admin@gov.in',
        phone: '+91 98765 00002',
        role: 'ADMIN',
        departmentId: 'WATER_SUPPLY',
      ),
      User(
        id: 'admin_sanitation',
        name: 'Suresh Patel (Sanitation Admin)',
        email: 'sanitation_admin@gov.in',
        phone: '+91 98765 00003',
        role: 'ADMIN',
        departmentId: 'SANITATION_WASTE',
      ),
      User(
        id: 'user_citizen',
        name: 'Janardhan Rao',
        email: 'citizen@example.com',
        phone: '+91 98765 43210',
        role: 'USER',
        departmentId: null,
      ),
    ];

    // 2. Pre-populated mock complaints (12 complaints across different statuses, coordinates, images)
    complaints = [
      Complaint(
        id: 'report-001',
        userId: 'user-001',
        title: 'Huge Pothole near Central Market',
        description: 'A deep pothole is blocking traffic near the entrance of Central Market. It has caused multiple two-wheeler accidents in the past few days.',
        category: 'Roads',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        assignedDepartment: 'Roads Dept',
        latitude: 12.9725,
        longitude: 77.5935,
        imageUrl: 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 36)),
        slaDeadline: DateTime.now().add(const Duration(hours: 12)),
        agentReasoning: 'CivicAgent Reason: Pothole located in a high-density market zone. Classified as HIGH priority to mitigate public safety hazards and vehicle damage.',
        timeline: [
          TimelineEvent(
            id: 'e1_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(hours: 36)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e1_2',
            status: 'SUBMITTED',
            title: 'AI Analysis Completed',
            description: 'CivicAgent analyzed report. Department: Roads & Highways, Priority: HIGH. Assigned to Roads & Highways Department.',
            timestamp: DateTime.now().subtract(const Duration(hours: 35, minutes: 45)),
            actor: 'CIVIC_AGENT',
          ),
          TimelineEvent(
            id: 'e1_3',
            status: 'IN_PROGRESS',
            title: 'Work In Progress',
            description: 'Assigned officer Accepted the grievance. Team dispatched to inspect and repair the road.',
            timestamp: DateTime.now().subtract(const Duration(hours: 24)),
            actor: 'OFFICER',
          ),
        ],
        comments: [
          Comment(id: 'c1_com1', userName: 'Rahul Dev', text: 'I also noticed this yesterday. It is highly dangerous.', timestamp: DateTime.now().subtract(const Duration(hours: 20))),
          Comment(id: 'c1_com2', userName: 'Priya Sen', text: 'Hope they fix it before the weekend rush.', timestamp: DateTime.now().subtract(const Duration(hours: 10))),
        ],
      ),
      Complaint(
        id: 'report-002',
        userId: 'user-002',
        title: 'Broken Streetlight on 5th Cross Street',
        description: 'The street lamp opposite House #42 is broken and flickering. The street is pitch black after 7 PM, making it unsafe for walking.',
        category: 'Electricity',
        status: 'RESOLVED',
        priority: 'MEDIUM',
        assignedDepartment: 'Electricity Dept',
        latitude: 12.9740,
        longitude: 77.5960,
        imageUrl: 'https://images.unsplash.com/photo-1509024644558-2f56ce76c490?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 48)),
        slaDeadline: DateTime.now().subtract(const Duration(hours: 24)),
        agentReasoning: 'CivicAgent Reason: Streetlight failure classified as MEDIUM priority. Standard SLA is 24 hours.',
        timeline: [
          TimelineEvent(
            id: 'e2_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(hours: 48)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e2_2',
            status: 'SUBMITTED',
            title: 'AI Routing Complete',
            description: 'CivicAgent categorized issue under Electricity. Assigned priority: MEDIUM.',
            timestamp: DateTime.now().subtract(const Duration(hours: 47, minutes: 50)),
            actor: 'CIVIC_AGENT',
          ),
          TimelineEvent(
            id: 'e2_3',
            status: 'IN_PROGRESS',
            title: 'Work Initiated',
            description: 'Maintenance team accepted. Replacement bulb ordered.',
            timestamp: DateTime.now().subtract(const Duration(hours: 30)),
            actor: 'OFFICER',
          ),
          TimelineEvent(
            id: 'e2_4',
            status: 'RESOLVED',
            title: 'Complaint Resolved',
            description: 'Officer uploaded resolution proof. Streetlight bulb has been replaced and verified working.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            actor: 'OFFICER',
          ),
        ],
        comments: [
          Comment(id: 'c2_com1', userName: 'Karan Mehra', text: 'This was fixed very fast! Thanks to the team.', timestamp: DateTime.now().subtract(const Duration(hours: 5))),
        ],
      ),
      Complaint(
        id: 'report-003',
        userId: 'user-003',
        title: 'Overflowing Sewage Drain near Park',
        description: 'The open drain near the public children\'s park is overflowing with sewage water. Terrible smell is spreading and it is a health hazard.',
        category: 'Sanitation',
        status: 'SUBMITTED',
        priority: 'HIGH',
        assignedDepartment: 'Sanitation Dept',
        latitude: 12.9700,
        longitude: 77.5910,
        imageUrl: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        slaDeadline: DateTime.now().add(const Duration(hours: 23, minutes: 15)),
        agentReasoning: 'CivicAgent Reason: Sanitation and drainage overflow near a public park involves high disease vectors. Priority set to HIGH. Instant department assignment routed.',
        timeline: [
          TimelineEvent(
            id: 'e3_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered successfully by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e3_2',
            status: 'SUBMITTED',
            title: 'CivicAgent Routing',
            description: 'AI detected high health risk factor. Categorized as Sanitation. Priority: HIGH. Allocated 24h SLA.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 44)),
            actor: 'CIVIC_AGENT',
          ),
        ],
        comments: [],
      ),
      Complaint(
        id: 'report-004',
        userId: 'user_citizen', // Owned by our mock citizen account
        title: 'Drinking Water Pipeline Leakage',
        description: 'Clean drinking water is bursting out of the road pipeline on 12th Main Road. Hundreds of gallons of water are being wasted.',
        category: 'Water',
        status: 'IN_PROGRESS',
        priority: 'MEDIUM',
        assignedDepartment: 'Water Dept',
        latitude: 12.9760,
        longitude: 77.5910,
        imageUrl: 'https://images.unsplash.com/photo-1542013936693-8848e574047a?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        slaDeadline: DateTime.now().add(const Duration(hours: 40)),
        agentReasoning: 'CivicAgent Reason: Routed to Water resources. Classified as MEDIUM priority because resource wastage is substantial but does not block pathways.',
        timeline: [
          TimelineEvent(
            id: 'e4_1',
            status: 'SUBMITTED',
            title: 'Complaint Submitted',
            description: 'Grievance registered by Citizen.',
            timestamp: DateTime.now().subtract(const Duration(hours: 8)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e4_2',
            status: 'IN_PROGRESS',
            title: 'Assigned to Water Board',
            description: 'routed to Water resources dept.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
            actor: 'OFFICER',
          ),
        ],
        comments: [
          Comment(id: 'c4_com1', userName: 'Janardhan Rao', text: 'This is near my office. The leakage is expanding.', timestamp: DateTime.now().subtract(const Duration(hours: 7))),
        ],
      ),
      Complaint(
        id: 'report-005',
        userId: 'user-005',
        title: 'Huge Garbage Accumulation',
        description: 'Garbage dump has not been cleaned for 5 days. Dogs are scattering it everywhere. It is a major health hazard.',
        category: 'Sanitation',
        status: 'SUBMITTED',
        priority: 'HIGH',
        assignedDepartment: 'Sanitation Dept',
        latitude: 12.9680,
        longitude: 77.5990,
        imageUrl: 'https://images.unsplash.com/photo-1611284446314-60a58ac0deb9?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        slaDeadline: DateTime.now().add(const Duration(hours: 22)),
        agentReasoning: 'CivicAgent Reason: Waste disposal blocks in residential areas are classified as HIGH priority due to sanitary risks.',
        timeline: [
          TimelineEvent(
            id: 'e5_1',
            status: 'SUBMITTED',
            title: 'Submitted by Citizen',
            description: 'Grievance successfully registered.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            actor: 'CITIZEN',
          ),
        ],
        comments: [],
      ),
      Complaint(
        id: 'report-006',
        userId: 'user-006',
        title: 'Exposed Electrical Wires near School',
        description: 'Live electric wires are hanging low from a pole right outside the government primary school. Kids play nearby, this is extremely critical.',
        category: 'Electricity',
        status: 'SUBMITTED',
        priority: 'HIGH',
        assignedDepartment: 'Electricity Dept',
        latitude: 12.9780,
        longitude: 77.5850,
        imageUrl: 'https://images.unsplash.com/photo-1526958016901-f54a01c00231?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        slaDeadline: DateTime.now().add(const Duration(hours: 5)),
        agentReasoning: 'CivicAgent Reason: Emergency hazard. Proximity to a school triggers maximum priority upgrade to HIGH (safety risk). Routed to Electricity Dept.',
        timeline: [
          TimelineEvent(
            id: 'e6_1',
            status: 'SUBMITTED',
            title: 'Critical Emergency Submitted',
            description: 'AI classified as emergency hazard.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            actor: 'CITIZEN',
          ),
        ],
        comments: [],
      ),
      Complaint(
        id: 'report-007',
        userId: 'user-007',
        title: 'Broken Benches in Cubbon Park',
        description: 'Two main benches in the central walking trail of the park are broken and unsafe for senior citizens to sit.',
        category: 'Public Infrastructure',
        status: 'RESOLVED',
        priority: 'LOW',
        assignedDepartment: 'Public Infrastructure Dept',
        latitude: 12.9730,
        longitude: 77.5920,
        imageUrl: 'https://images.unsplash.com/photo-1597200381847-30ec200eeb9a?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        slaDeadline: DateTime.now().subtract(const Duration(days: 1)),
        agentReasoning: 'CivicAgent Reason: Park bench repairs represent aesthetic and public seating issues. Classified as LOW priority.',
        timeline: [
          TimelineEvent(
            id: 'e7_1',
            status: 'SUBMITTED',
            title: 'Submitted',
            description: 'Bench grievance filed.',
            timestamp: DateTime.now().subtract(const Duration(days: 4)),
            actor: 'CITIZEN',
          ),
          TimelineEvent(
            id: 'e7_2',
            status: 'RESOLVED',
            title: 'Benches Replaced',
            description: 'Grievance cleared. Benches replaced with new cast iron structures.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            actor: 'OFFICER',
          ),
        ],
        comments: [],
      ),
      Complaint(
        id: 'report-008',
        userId: 'user-008',
        title: 'Vector Breeding Swamp Blockage',
        description: 'Stagnant swamp water near residential layouts has created a massive mosquito hazard. Dengue cases are surging in this ward.',
        category: 'Public Infrastructure',
        status: 'IN_PROGRESS',
        priority: 'HIGH',
        assignedDepartment: 'Public Infrastructure Dept',
        latitude: 12.9550,
        longitude: 77.6100,
        imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        slaDeadline: DateTime.now().add(const Duration(hours: 24)),
        agentReasoning: 'CivicAgent Reason:SURGE in dengue cases triggers high priority rating. Classification routed under Public Health / Municipal Services.',
        timeline: [
          TimelineEvent(
            id: 'e8_1',
            status: 'SUBMITTED',
            title: 'Health Complaint Submitted',
            description: 'Routing vector control teams.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            actor: 'CITIZEN',
          ),
        ],
        comments: [
          Comment(id: 'c8_com1', userName: 'Harish R', text: 'My son is hospitalized due to malaria. Please clear this immediately.', timestamp: DateTime.now().subtract(const Duration(days: 1))),
        ],
      ),
      Complaint(
        id: 'report-009',
        userId: 'user_citizen', // Owned by our mock citizen
        title: 'Severe Road Crack on Flyover',
        description: 'A structural crack has formed on the main flyover slab. Vehicles get jerked when passing over it. Needs inspection.',
        category: 'Roads',
        status: 'SUBMITTED',
        priority: 'HIGH',
        assignedDepartment: 'Roads Dept',
        latitude: 12.9900,
        longitude: 77.5990,
        imageUrl: 'https://images.unsplash.com/photo-1599740831119-07284763f831?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        slaDeadline: DateTime.now().add(const Duration(hours: 19)),
        agentReasoning: 'CivicAgent Reason: Structural integrity of public flyovers is highly safety critical. Upgraded to HIGH priority.',
        timeline: [
          TimelineEvent(
            id: 'e9_1',
            status: 'SUBMITTED',
            title: 'Submitted by Citizen',
            description: 'Structural grievance routing.',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            actor: 'CITIZEN',
          ),
        ],
        comments: [],
      ),
      Complaint(
        id: 'report-010',
        userId: 'user-010',
        title: 'Low Water Pressure in Layout',
        description: 'Since 3 days, water pressure in our taps is very low. We cannot fill our overhead tanks. Please inspect the main pump.',
        category: 'Water',
        status: 'SUBMITTED',
        priority: 'MEDIUM',
        assignedDepartment: 'Water Dept',
        latitude: 12.9500,
        longitude: 77.5800,
        imageUrl: 'https://images.unsplash.com/photo-1542013936693-8848e574047a?q=80&w=600',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        slaDeadline: DateTime.now().add(const Duration(hours: 36)),
        agentReasoning: 'CivicAgent Reason: Water supply pressure requires pump review. MEDIUM priority.',
        timeline: [
          TimelineEvent(
            id: 'e10_1',
            status: 'SUBMITTED',
            title: 'Submitted',
            description: 'Low water supply pressure logged.',
            timestamp: DateTime.now().subtract(const Duration(hours: 12)),
            actor: 'CITIZEN',
          ),
        ],
        comments: [],
      )
    ];

    // 3. Pre-populated mock notifications
    notifications = [
      UserNotification(
        id: 'notification-001',
        userId: 'user_citizen',
        reportId: 'report-002',
        type: 'REPORT_RESOLVED',
        title: 'Issue Cleared',
        message: 'Your streetlight complaint on 5th Cross Street has been resolved successfully.',
        isRead: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ];
  }

  // API helper actions
  void addComment(String complaintId, Comment comment) {
    final index = complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final old = complaints[index];
      final List<Comment> updatedComments = List.from(old.comments)..add(comment);
      
      complaints[index] = Complaint(
        id: old.id,
        userId: old.userId,
        title: old.title,
        description: old.description,
        category: old.category,
        status: old.status,
        priority: old.priority,
        assignedDepartment: old.assignedDepartment,
        latitude: old.latitude,
        longitude: old.longitude,
        imageUrl: old.imageUrl,
        createdAt: old.createdAt,
        slaDeadline: old.slaDeadline,
        agentReasoning: old.agentReasoning,
        timeline: old.timeline,
        comments: updatedComments,
      );
    }
  }

  void resolveComplaint(String complaintId, String adminName) {
    final index = complaints.indexWhere((c) => c.id == complaintId);
    if (index != -1) {
      final old = complaints[index];
      
      final updatedTimeline = List<TimelineEvent>.from(old.timeline)
        ..add(TimelineEvent(
          id: 'e_resolved_${DateTime.now().millisecondsSinceEpoch}',
          status: 'RESOLVED',
          title: 'Grievance Resolved',
          description: 'Grievance marked as resolved by admin $adminName.',
          timestamp: DateTime.now(),
          actor: 'OFFICER',
        ));

      complaints[index] = Complaint(
        id: old.id,
        userId: old.userId,
        title: old.title,
        description: old.description,
        category: old.category,
        status: 'RESOLVED',
        priority: old.priority,
        assignedDepartment: old.assignedDepartment,
        latitude: old.latitude,
        longitude: old.longitude,
        imageUrl: old.imageUrl,
        createdAt: old.createdAt,
        slaDeadline: old.slaDeadline,
        agentReasoning: old.agentReasoning,
        timeline: updatedTimeline,
        comments: old.comments,
      );

      // Trigger user notification
      final newNotif = UserNotification(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: old.userId,
        reportId: old.id,
        type: 'REPORT_RESOLVED',
        title: 'Issue Cleared',
        message: 'Your complaint "${old.title}" has been resolved by $adminName.',
        isRead: false,
        createdAt: DateTime.now(),
      );
      notifications.insert(0, newNotif);
    }
  }
}
