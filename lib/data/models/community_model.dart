class Community {
  final String id;
  final String name;
  final String description;
  final String imageUrl;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });
}

final List<Community> communitiesList = [
  const Community(
    id: '1',
    name: 'DUBAI LAND',
    description: 'Dubailand is a massive residential and entertainment destination, featuring a diverse range of communities, world-class theme parks, and lifestyle amenities.',
    imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&q=80',
  ),
  const Community(
    id: '2',
    name: 'JUMEIRAH GARDEN CITY',
    description: 'Jumeirah Garden City is a modern redevelopment project designed as a sustainable and vibrant urban community in the heart of Al Satwa.',
    imageUrl: 'https://images.unsplash.com/photo-1548560786-0770bd695105?auto=format&fit=crop&q=80',
  ),
  const Community(
    id: '3',
    name: 'MEYDAN HORIZON',
    description: 'Meydan Horizon is a world-class mixed-use development set within the prestigious Meydan area, offering high-end residences and luxury amenities.',
    imageUrl: 'https://images.unsplash.com/photo-1518684079-3c830dcef090?auto=format&fit=crop&q=80',
  ),
  const Community(
    id: '4',
    name: 'DUBAI ISLANDS',
    description: 'Dubai Islands is an ambitious waterfront project formerly known as Deira Islands, featuring man-made islands designed for luxury living and tourism.',
    imageUrl: 'https://images.unsplash.com/photo-1582672060674-bc2bd808a8b5?auto=format&fit=crop&q=80',
  ),
  const Community(
    id: '5',
    name: 'DUBAI SOUTH',
    description: 'Dubai South is a city-scale development envisioned as the "Project of the Century," housing the Al Maktoum International Airport and Expo 2020 site.',
    imageUrl: 'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?auto=format&fit=crop&q=80',
  ),
];
