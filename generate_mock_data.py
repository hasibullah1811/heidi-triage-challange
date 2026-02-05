import json
import random
import uuid
from datetime import datetime, timedelta

PATIENTS = ["Sarah Jones", "John Smith", "Michael Wong", "Emma Davis", "David Miller", "Unknown Caller", "Mrs. Higgins"]
DRUGS = ["Perindopril", "Amoxicillin", "Panadol", "Oxycodone", "Metformin"]
DOCTORS = ["Dr. Kelly", "Dr. Lee", "Dr. Chen", "the nurse"]

# Added specific "keywords" to every template so the UI can explain "Why"
TRANSCRIPT_TEMPLATES = [
    {
        "text": "Hi, this is {name}. My husband woke up and his chest feels really heavy... he is sweating and looks pale. Please call back immediately.",
        "type": "emergency",
        "keywords": ["chest heavy", "sweating", "pale", "call back immediately"]
    },
    {
        "text": "Hello, it's {name}. I'm running low on my {drug}. Can {doctor} send a script to the chemist? I'll pick it up Thursday.",
        "type": "script",
        "keywords": ["running low", "script", "chemist"]
    },
    {
        "text": "Hi, {name} here. I need to cancel my appointment for tomorrow morning. I've been called into work. Sorry!",
        "type": "admin",
        "keywords": ["cancel", "appointment", "tomorrow morning"]
    },
    {
        "text": "Uhh, hi. I missed a call from this number? Not sure who called me. Bye.",
        "type": "unknown",
        "keywords": ["missed a call", "who called me"]
    },
    {
        "text": "This is {name}. I'm still waiting for my blood test results from last week. Nobody has called me back and I'm getting worried.",
        "type": "results",
        "keywords": ["blood test results", "waiting", "worried"]
    },
    {
        "text": "I need to speak to {doctor} NOW. The pharmacy refused to dispense my {drug} and said I need a new authority. This is ridiculous.",
        "type": "complaint",
        "keywords": ["speak to doctor NOW", "pharmacy refused", "authority"]
    }
]

# I CALL IT THE "FAKE LLM" ENGINE ---
def analyze_transcript(text, template_type):
    # Default values
    urgency = "low"
    intent = "unknown"
    suggested_actions = ["Callback"]
    summary = "Message received."
    confidence = round(random.uniform(0.70, 0.99), 2)

    # Rule-based logic (The "AI")
    if template_type == "emergency":
        urgency = "critical"
        intent = "emergency"
        suggested_actions = ["CALL NOW", "Alert On-Call Doctor"]
        summary = "Reports symptoms of cardiac distress (chest heaviness, sweating)."
        confidence = 0.99
    
    elif template_type == "script":
        urgency = "low"
        intent = "prescription"
        suggested_actions = ["Approve Script", "SMS 'Ready'"]
        summary = "Requesting repeat prescription."
    
    elif template_type == "admin":
        urgency = "low"
        intent = "scheduling"
        suggested_actions = ["Remove from Calendar", "Send Confirmation"]
        summary = "Cancellation request for upcoming appointment."
        
    elif template_type == "results":
        urgency = "medium"
        intent = "medical_records"
        suggested_actions = ["Check Pathology Inbox", "Task Nurse"]
        summary = "Patient chasing blood test results."

    elif template_type == "complaint":
        urgency = "high"
        intent = "complaint"
        suggested_actions = ["Review File", "Call Patient Calmly"]
        summary = "Dispute regarding medication authority at pharmacy."
    
    return urgency, intent, suggested_actions, summary, confidence

# GENERATION LOOP 

def generate_mock_data(count=12):
    output_data = []
    
    # Start time: 8:00 AM today
    base_time = datetime.now().replace(hour=8, minute=0, second=0, microsecond=0)

    for i in range(count):
        # Pick a random scenario
        template = random.choice(TRANSCRIPT_TEMPLATES)
        
        # Fill in the blanks
        patient = random.choice(PATIENTS)
        text = template["text"].format(
            name=patient, 
            drug=random.choice(DRUGS), 
            doctor=random.choice(DOCTORS)
        )
        
        # Run the "AI" analysis
        urgency, intent, actions, summary, confidence = analyze_transcript(text, template["type"])
        
        # Add random time increments
        base_time += timedelta(minutes=random.randint(5, 45))
        
        entry = {
            "id": f"vm_{uuid.uuid4().hex[:6]}",
            "patientName": patient,
            "timeReceived": base_time.strftime("%I:%M %p"),
            "fullTranscript": text,
            "summary": summary,
            "intent": intent,     
            "urgency": urgency,   
            "suggestedActions": actions,
            "confidenceScore": confidence,
            "detectedKeywords": template["keywords"] # <--- NEW FIELD ADDED HERE
        }
        output_data.append(entry)

    return output_data

# EXECUTION 
if __name__ == "__main__":
    data = generate_mock_data(15) 
    
    # Dump to JSON file
    with open("mock_voicemails.json", "w") as f:
        json.dump(data, f, indent=2)
        
    print(f"✅ Successfully generated {len(data)} mock voicemails with keywords in 'mock_voicemails.json'")