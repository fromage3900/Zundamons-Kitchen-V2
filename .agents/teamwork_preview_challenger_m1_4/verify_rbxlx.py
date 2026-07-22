import xml.etree.ElementTree as ET

tree = ET.parse('build/Zundamons-kItchen.rbxlx')
root = tree.getroot()

required_events = [
    'ShowVNDialogue', 'ChefStatsUpdate', 'StylePointsUpdate', 'OutfitUnlock',
    'ChallengeMode', 'ChallengeModeStatus', 'DailyChallenge', 'DailyChallengeStatus'
]

required_functions = [
    'GiveLoot', 'sellLoot'
]

found_events = set()
found_functions = set()

for item in root.iter('Item'):
    c_class = item.attrib.get('class')
    props = item.find('Properties')
    if props is not None:
        for s in props.findall('string'):
            if s.attrib.get('name') == 'Name' and s.text:
                if c_class == 'RemoteEvent':
                    found_events.add(s.text)
                elif c_class == 'RemoteFunction':
                    found_functions.add(s.text)

print("=== REMOTE EVENTS FOUND ===")
all_events_found = True
for req in required_events:
    is_found = req in found_events
    print(f"  {req}: {'EXISTS' if is_found else 'MISSING'}")
    if not is_found:
        all_events_found = False

print("\n=== REMOTE FUNCTIONS FOUND ===")
all_functions_found = True
for req in required_functions:
    is_found = req in found_functions
    print(f"  {req}: {'EXISTS' if is_found else 'MISSING'}")
    if not is_found:
        all_functions_found = False

print("\nOverall RemoteEvents Verification:", "PASSED" if all_events_found else "FAILED")
print("Overall RemoteFunctions Verification:", "PASSED" if all_functions_found else "FAILED")
