import '../models/lead_model.dart';

class MockLeadRepository {
  static final List<Lead> leads = [
    Lead(
      id: '1',
      title: 'Wedding Reception',
      date: 'Oct 24, 2024',
      time: '5:00 PM - 10:00 PM',
      location: 'Los Angeles, CA',
      matchScore: 98,
      budget: 5000.0,
      guests: 150,
      responseTime: '15m',
      clientName: 'Sarah Johnson',
      clientMessage:
          'Looking for a modern floral arrangement for our corporate gala. Needs to be sleek and professional but with a pop of seasonal color.',
      venueName: 'The Glass House',
      venueAddress: '280 Elizabeth St, New York, NY',
      clientImageUrl:
          'https://ui-avatars.com/api/?name=Sarah+Johnson&background=f0e4d7&color=1a1a24',
      isHighValue: true,
      lastActive: '2h ago',
      phoneNumber: '+256700000001',
    ),
    Lead(
      id: '2',
      title: 'Corporate Gala',
      date: 'Nov 12, 2024',
      time: '6:00 PM - 11:00 PM',
      location: 'San Francisco, CA',
      matchScore: 85,
      budget: 12000.0,
      guests: 300,
      responseTime: '30m',
      clientName: 'Michael Chen',
      clientMessage:
          'Annual corporate celebration. Need premium catering and audio-visual support.',
      venueName: 'Palace Hotel',
      venueAddress: '2 New Montgomery St, San Francisco, CA',
      clientImageUrl:
          'https://ui-avatars.com/api/?name=Michael+Chen&background=dcfce7&color=166534',
      isHighValue: true,
      lastActive: '1h ago',
      phoneNumber: '+256700000002',
    ),
  ];

  static Lead? getById(String id) {
    try {
      return leads.firstWhere((lead) => lead.id == id);
    } catch (e) {
      return null;
    }
  }
}
