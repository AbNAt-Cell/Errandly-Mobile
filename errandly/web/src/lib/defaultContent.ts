export const DEFAULT_CONTENT = {
  "home": {
    "meta": {
      "title": "Errand — Your Trusted Local Errand Service",
      "description": "Connect with verified local runners to get your errands done safely and quickly."
    },
    "nav": {
      "logo": "/logo.png",
      "logoAlt": "Errand Logo",
      "brandName": "Errand",
      "links": [
        { "label": "How it Works", "href": "#how-it-works" },
        { "label": "Services", "href": "#services" },
        { "label": "About", "href": "/about" },
        { "label": "Careers", "href": "/careers" },
        { "label": "Contact", "href": "/contact" }
      ],
      "loginLabel": "Login",
      "loginHref": "/auth/login",
      "ctaLabel": "Get Started",
      "ctaHref": "/auth/register"
    },
    "hero": {
      "badge": {
        "icon": "location_on",
        "text": "Live in Uyo"
      },
      "heading": "Get Any Errand Done",
      "headingAccent": "Safely & Fast",
      "description": "Uyo's most reliable hyperlocal marketplace. We connect you with vetted runners to handle your deliveries, grocery shopping, and daily tasks within minutes.",
      "ctaPrimary": { "label": "Post an Errand", "icon": "arrow_forward", "href": "/customer/errands/new" },
      "ctaSecondary": { "label": "Become a Runner", "href": "/auth/register?role=runner" },
      "trustText": "Trusted by 10k+ Residents in Uyo",
      "trustAvatars": [
        "https://lh3.googleusercontent.com/aida-public/AB6AXuABkNl5SrB9YeKto4k8yycV_WnJVU07sTSUe3gCDdupkIew3kJEB5OG--KHFLZfkRIPnk8X6vUuqTH_mJKw8TIwUNPK6PNvgxCXNQsd75PzYG24Ci3oASPjWwMeMwo7NzWyqxsTiJbrZnj_pvjRdpz4WDrRFNt87BBS2xUteTLsbbMhaz_0_saQDL37LajsCZdaDSKuCfZnMeKKscITKElNA4w4p_8Wqw6XwiMwDa3IhwY5LPCPP5siUi45N5pd2YZt3iLKfjO9V8z1",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuBFeel75V2GoKQ30kWWlNaWnHvs6IggnU4RumSBTaAe2seTEkFOQi23ZRWFYWAweqSikdUYkDZa5ZAeRZchPzXNzuwTycU1O1cPtUlg6GFou7GWhQZT85EV2GptzF168EOzY05YzSrWy8TcVrlzRlsvjz_neOGG1KJL5VA6C9WTujU7svwrp3h3vxSZWc39aFIND12bTexi0ndu5gvcgv-qCzGPTAp-g6F89BkCSfP-wjlXS5Hm3QwRUDZ9jfJUXbxrlhXTrp_LMUBN",
        "https://lh3.googleusercontent.com/aida-public/AB6AXuCuybloDLRXvkiC2gLCz0lTLzfVfi0u4SJk2kMy5QRwYteSiGZGb3UkDYIBARqqilqHY0uE05MWosmpPB91I9GnZQ5yF1wVwTsCokuqt09Rpd_KVOKvDWkbxXaDCZeSKaX1Aemy4X-5Uak2BbYRxLVNJQex58ZWQweQ3EZwDo5cR8a2N_b7Yd12aikqBHiVNXeva1mBhPhzATn-OeDacmvlZno8-NWZEpbzoUs0tFAUl4C7QS52pYumAwnTpKSD5jVlOKeXpb9ARRzm"
      ],
      "phoneImage": "https://lh3.googleusercontent.com/aida-public/AB6AXuDmtTsCTMpo0xS5GS1iM7mSO7XrBlik3Qyrw5F9neMbwdYLzYFDHFP4sfg6-Vpg78OuCrvy_P-PTKOcRCSZLCCyGUZUCbkdmZwgyDWi4y2Gk7biTpU02YNX0-TMrZRiBV4AkEHev8fI62oLQctGlLgfzPSuAdS1w6gOIsAKmqqCy-ykFF6yO2ZXctY4nXMDY4J4ROsiHRrG5i84eMLD9StUs1gBvW8acl4TkGoJNdzJkFlxeW4g7YOQBAxH7nCMQXCvnbghQ5YRTJi5"
    },
    "stats": [
      { "value": "10+", "label": "Errands Completed" },
      { "value": "2,500+", "label": "Verified Runners" },
      { "value": "4.8/5", "label": "Average Rating" },
      { "value": "5", "label": "Areas Covered" }
    ],
    "services": {
      "heading": "What Can We Help With?",
      "description": "From essential tasks to urgent deliveries, our runners have you covered.",
      "items": [
        { "icon": "shopping_cart", "title": "Grocery Shopping", "desc": "Fresh items from Itam Market delivered to your door." },
        { "icon": "package_2", "title": "Package Delivery", "desc": "Secure document or item drop-off across Uyo." },
        { "icon": "restaurant", "title": "Food Pickup", "desc": "Your favorite local meals from any restaurant." },
        { "icon": "receipt_long", "title": "Bill Payments", "desc": "PHED, Water bills, or DSTV top-ups handled fast." },
        { "icon": "medication", "title": "Pharmacy Run", "desc": "Essential medicines from trusted local clinics." },
        { "icon": "local_laundry_service", "title": "Laundry Services", "desc": "Pick up and drop off for your dry cleaning." },
        { "icon": "celebration", "title": "Gift Surprises", "desc": "Send flowers or curated gifts to loved ones." },
        { "icon": "more_horiz", "title": "Anything Else", "desc": "Just describe your errand, we'll get it done." }
      ]
    },
    "howItWorks": {
      "heading": "How Errand Works",
      "steps": [
        { "number": "1", "title": "Describe Errand", "description": "Tell us what you need and set your location." },
        { "number": "2", "title": "Secure Funds", "description": "Your money is held safely until the errand is done.", "badge": "Secure Escrow", "icon": "lock", "highlighted": true },
        { "number": "3", "title": "Runner Bids", "description": "A verified nearby runner accepts your errand." },
        { "number": "4", "title": "Real-time Track", "description": "Watch your runner move live on the map." },
        { "number": "5", "title": "Confirm Delivery", "description": "Check the item and release the unique OTP code." },
        { "number": "6", "title": "Runner Paid", "description": "Funds are released and you can leave a review!", "icon": "check_circle", "isComplete": true }
      ]
    },
    "safety": {
      "heading": "Built for",
      "headingAccent": "Safety First",
      "features": [
        { "icon": "verified_user", "title": "Vetted Runners", "description": "Every runner undergoes Ninja background checks and physical ID verification." },
        { "icon": "policy", "title": "Insured Tasks", "description": "Your items are protected. We provide micro-insurance for high-value errands." },
        { "icon": "support_agent", "title": "24/7 Support", "description": "A dedicated local team is ready to intervene if anything goes wrong." },
        { "icon": "shield_person", "title": "OTP Security", "description": "Errands are only finalized when you provide the secret 4-digit code." }
      ],
      "banner": {
        "icon": "lock",
        "text": "Your privacy and data are protected with bank-grade AES-256 encryption.",
        "linkText": "Learn about our Security Protocols",
        "linkHref": "/privacy"
      }
    },
    "testimonials": {
      "heading": "Trusted by the Community",
      "items": [
        { "text": "Errand saved my business. I can now send documents across Uyo without leaving my office. The runners are professional and trustworthy.", "name": "Adaeze O.", "role": "Business Owner, Uyo" },
        { "text": "I use Errand weekly for grocery runs. The live tracking gives me peace of mind and the prices are fair.", "name": "Chidi M.", "role": "Student, Ewet Housing" },
        { "text": "I earn ₦80,000+ monthly as a runner. The app is easy to use and payments are always on time.", "name": "Emem A.", "role": "Runner, Ikot Ekpene Road" }
      ]
    },
    "footer": {
      "logo": "/logo.png",
      "logoAlt": "Errand Logo",
      "brandName": "Errand",
      "tagline": "Nigeria's fastest local errand network",
      "columns": [
        {
          "title": "Company",
          "links": [
            { "label": "About Us", "href": "/about" },
            { "label": "Contact", "href": "/contact" },
            { "label": "Careers", "href": "/careers" }
          ]
        },
        {
          "title": "Services",
          "links": [
            { "label": "Become a Runner", "href": "/auth/register?role=runner" },
            { "label": "Post an Errand", "href": "/customer/errands/new" },
            { "label": "Admin Portal", "href": "/admin/dashboard" }
          ]
        },
        {
          "title": "Support",
          "links": [
            { "label": "+234 900 000 0000", "href": "tel:+2349000000000" },
            { "label": "support@errand.com", "href": "mailto:support@errand.com" },
            { "label": "Privacy Policy", "href": "/privacy" }
          ]
        }
      ],
      "copyright": "© {year} Errand. All rights reserved."
    }
  },
  "about": {
    "meta": {
      "title": "About Us — Errand",
      "description": "Learn about our mission to revolutionize hyperlocal logistics in Nigeria."
    },
    "hero": {
      "badge": { "icon": "groups", "text": "OUR STORY" },
      "heading": "Built for Uyo. Powered by Trust.",
      "description": "Errand was born from a simple idea: what if anyone could get anything done, quickly and safely, within their own city? We started in Uyo, Akwa Ibom, and we're just getting started."
    },
    "mission": {
      "heading": "Our Mission",
      "description": "To become the most trusted hyperlocal logistics and errand platform in Nigeria — empowering communities, creating jobs, and making daily life simpler for everyone.",
      "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuAtoLkSdiXffuFbnVhswbuPrOl0qdrRjKJ_-sQDuYgWelQbjBpmYXVErEo8KxScqzYdSq691gY2GDtg2lSGQYxLZGMDMz-m_gj1DcEJ3YI_0TBxMa25n5SdrW7xucEvyA3v_EsPuBuEBat0loru44lRWOD_mPtouvEKyyVEbKJ-82-M9tktqgILkLlNS5gdjDD9CkRf-ULs13rano6l_8qwA0q318iVaH1UbwDdGJXSUpC0yhRniT0DDMiwgjXv2W83CTpKnph7Asv4",
      "imageAlt": "Errand team collaborating in office"
    },
    "values": {
      "heading": "Our Core Values",
      "description": "The principles that guide every decision we make and every errand we complete.",
      "items": [
        { "icon": "handshake", "title": "Community First", "description": "We exist because of the people we serve. Every feature, every hire, every decision starts with our community." },
        { "icon": "speed", "title": "Speed Matters", "description": "In logistics, time is everything. We optimize relentlessly to deliver faster, every single time." },
        { "icon": "verified_user", "title": "Trust & Safety", "description": "From background checks to escrow payments, we build layers of trust into every transaction." },
        { "icon": "lightbulb", "title": "Street-Smart Innovation", "description": "We don't copy Silicon Valley. We build solutions grounded in Nigeria's reality — practical, resilient, and local." }
      ]
    },
    "stats": {
      "heading": "Errand by the Numbers",
      "items": [
        { "value": "10+", "label": "Errands Completed", "icon": "package_2" },
        { "value": "2,500+", "label": "Verified Runners", "icon": "directions_run" },
        { "value": "4.8/5", "label": "Customer Rating", "icon": "star" },
        { "value": "5", "label": "Areas Covered", "icon": "map" }
      ]
    },
    "team": {
      "heading": "Meet the Team",
      "description": "A passionate group of operators, engineers, and community builders driving Errand forward.",
      "members": [
        { "name": "Founder & CEO", "role": "Leading the vision for hyperlocal logistics in Nigeria.", "image": "", "icon": "person" },
        { "name": "Head of Operations", "role": "Ensuring every errand runs like clockwork across Uyo.", "image": "", "icon": "settings" },
        { "name": "Lead Engineer", "role": "Building the technology that powers real-time tracking and escrow.", "image": "", "icon": "code" },
        { "name": "Community Manager", "role": "Keeping our runners and customers connected and supported.", "image": "", "icon": "forum" }
      ]
    },
    "cta": {
      "heading": "Join the Movement",
      "description": "Whether you need help with errands or want to earn by running them, Errand is your platform.",
      "primaryButton": { "label": "Post an Errand", "href": "/customer/errands/new" },
      "secondaryButton": { "label": "Become a Runner", "href": "/auth/register?role=runner" }
    }
  },
  "careers": {
    "meta": {
      "title": "Careers | Errand — Join the Local Movement",
      "description": "Join our team and help build the future of hyperlocal logistics in Nigeria."
    },
    "hero": {
      "badge": { "icon": "", "text": "WE ARE HIRING" },
      "heading": "Join the Local Movement.",
      "description": "We're building the future of hyperlocal logistics and community help in Nigeria. Join our team in Uyo as we redefine how people get things done.",
      "ctaPrimary": { "label": "View Open Roles", "href": "#open-roles" },
      "ctaSecondary": { "label": "Our Culture", "href": "#culture" }
    },
    "whyJoinUs": {
      "heading": "Why Join Us?",
      "description": "Empowering our team members with the tools they need to thrive while making a real difference in the local economy.",
      "items": [
        { "icon": "trending_up", "title": "Growth", "description": "Personal and professional development with clear career pathways in a fast-scaling tech startup environment." },
        { "icon": "public", "title": "Impact", "description": "Directly improve lives by solving real logistics challenges for thousands of residents and business owners across Uyo." },
        { "icon": "schedule", "title": "Flexibility", "description": "We value output over hours. Work in an environment that respects your time and fosters a healthy work-life balance." }
      ]
    },
    "culture": {
      "heading": "Street-smart, Trust, and Speed.",
      "values": [
        { "title": "Street-smart", "description": "We understand the pulse of Nigeria. Our solutions are practical, grounded, and designed for the real world." },
        { "title": "Trust", "description": "Community is our foundation. We build relationships based on radical transparency and reliability." },
        { "title": "Speed", "description": "Logistics is a race against time. We move fast, iterate quickly, and deliver without excuses." }
      ],
      "image": "https://lh3.googleusercontent.com/aida-public/AB6AXuAtoLkSdiXffuFbnVhswbuPrOl0qdrRjKJ_-sQDuYgWelQbjBpmYXVErEo8KxScqzYdSq691gY2GDtg2lSGQYxLZGMDMz-m_gj1DcEJ3YI_0TBxMa25n5SdrW7xucEvyA3v_EsPuBuEBat0loru44lRWOD_mPtouvEKyyVEbKJ-82-M9tktqgILkLlNS5gdjDD9CkRf-ULs13rano6l_8qwA0q318iVaH1UbwDdGJXSUpC0yhRniT0DDMiwgjXv2W83CTpKnph7Asv4",
      "imageAlt": "Errand team collaborating"
    },
    "openRoles": {
      "heading": "Open Roles",
      "description": "Found a position that fits? We'd love to hear from you.",
      "roles": [
        { "title": "Operations Manager", "type": "Full-time", "typeColor": "orange", "location": "Uyo, AK", "locationIcon": "location_on", "compensation": "Competitive + Equity", "compensationIcon": "payments" },
        { "title": "Support Lead", "type": "Full-time", "typeColor": "orange", "location": "Remote / Uyo", "locationIcon": "location_on", "compensation": "Performance Bonuses", "compensationIcon": "payments" },
        { "title": "Fleet Supervisor", "type": "Field-based", "typeColor": "blue", "location": "Uyo, AK", "locationIcon": "location_on", "compensation": "Fuel & Tech allowance", "compensationIcon": "commute" }
      ],
      "spontaneous": {
        "heading": "Don't see a perfect fit?",
        "description": "We're always looking for talented street-smart professionals. Send us a spontaneous application and tell us how you can help Errand grow.",
        "buttonLabel": "Send General Application"
      }
    }
  },
  "contact": {
    "meta": {
      "title": "Contact Us — Errand",
      "description": "Get in touch with the Errand team. We're here to help with any questions or concerns."
    },
    "hero": {
      "badge": { "icon": "mail", "text": "GET IN TOUCH" },
      "heading": "We'd Love to Hear From You.",
      "description": "Whether you have a question, feedback, or need help with an errand — our team is ready to assist."
    },
    "contactInfo": {
      "heading": "Contact Information",
      "items": [
        { "icon": "location_on", "title": "Visit Us", "details": ["Errand HQ", "123 Abak Road, Uyo", "Akwa Ibom State, Nigeria"] },
        { "icon": "phone", "title": "Call Us", "details": ["+234 900 000 0000", "+234 800 000 0000"] },
        { "icon": "mail", "title": "Email Us", "details": ["support@errand.com", "careers@errand.com"] },
        { "icon": "schedule", "title": "Business Hours", "details": ["Monday — Friday: 8AM — 8PM", "Saturday: 9AM — 5PM", "Sunday: Closed"] }
      ]
    },
    "form": {
      "heading": "Send Us a Message",
      "description": "Fill out the form below and we'll get back to you within 24 hours.",
      "fields": [
        { "name": "fullName", "label": "Full Name", "type": "text", "placeholder": "Enter your full name", "required": true },
        { "name": "email", "label": "Email Address", "type": "email", "placeholder": "you@example.com", "required": true },
        { "name": "phone", "label": "Phone Number", "type": "tel", "placeholder": "+234...", "required": false },
        { "name": "subject", "label": "Subject", "type": "select", "options": ["General Inquiry", "Runner Support", "Customer Issue", "Partnership", "Careers", "Other"], "required": true },
        { "name": "message", "label": "Message", "type": "textarea", "placeholder": "Tell us how we can help...", "required": true }
      ],
      "submitLabel": "Send Message",
      "submitIcon": "send"
    },
    "faq": {
      "heading": "Frequently Asked Questions",
      "items": [
        { "question": "How quickly will I get a response?", "answer": "We aim to respond to all inquiries within 24 hours during business days." },
        { "question": "Can I become a runner?", "answer": "Yes! Visit our Become a Runner page to start your application process. You'll need a valid ID and to pass our verification checks." },
        { "question": "Is Errand available outside Uyo?", "answer": "We're currently focused on Uyo, Akwa Ibom State. We plan to expand to other cities in Nigeria soon." },
        { "question": "How do I report an issue with an errand?", "answer": "You can report issues through your dashboard under the errand details, or contact our support team directly via phone or email." }
      ]
    }
  },
  "privacy": {
    "meta": {
      "title": "Privacy Policy — Errand",
      "description": "Learn how Errand collects, uses, and protects your personal information."
    },
    "hero": {
      "badge": { "icon": "shield", "text": "YOUR PRIVACY MATTERS" },
      "heading": "Privacy Policy",
      "description": "Last updated: July 2026. This Privacy Policy describes how Errand collects, uses, and shares your personal information."
    },
    "sections": [
      {
        "title": "1. Information We Collect",
        "icon": "database",
        "content": [
          {
            "subtitle": "Personal Information",
            "text": "When you create an account, we collect your name, email address, phone number, and physical address. If you register as a runner, we also collect your government-issued ID, bank account details for payments, and a photograph for identity verification."
          },
          {
            "subtitle": "Usage Information",
            "text": "We automatically collect information about how you use our platform, including your device type, IP address, browser type, pages visited, and timestamps. This helps us improve our services and troubleshoot issues."
          },
          {
            "subtitle": "Location Data",
            "text": "With your consent, we collect precise location data to match you with nearby runners, provide live tracking during errands, and optimize delivery routes. You can disable location sharing in your device settings, but this may limit some features."
          }
        ]
      },
      {
        "title": "2. How We Use Your Information",
        "icon": "settings",
        "content": [
          {
            "subtitle": "",
            "text": "We use your personal information to provide, maintain, and improve our services. This includes processing transactions, facilitating communication between customers and runners, verifying identities, preventing fraud, sending notifications about your errands, and providing customer support. We may also use anonymized data for analytics and to develop new features."
          }
        ]
      },
      {
        "title": "3. How We Share Your Information",
        "icon": "share",
        "content": [
          {
            "subtitle": "With Other Users",
            "text": "When you post an errand, your first name and general location are shared with runners who may accept the job. When a runner accepts, their name, photo, and real-time location are shared with you for tracking purposes."
          },
          {
            "subtitle": "With Service Providers",
            "text": "We share information with third-party service providers who assist us in payment processing, identity verification, cloud hosting, analytics, and customer support."
          },
          {
            "subtitle": "For Legal Compliance",
            "text": "We may disclose your information if required by law, in response to legal processes, or to protect the rights, property, and safety of Errand, our users, or the public."
          }
        ]
      },
      {
        "title": "4. Data Security",
        "icon": "lock",
        "content": [
          {
            "subtitle": "",
            "text": "We implement industry-standard security measures including AES-256 encryption for data at rest, TLS 1.3 for data in transit, and regular security audits. Payment information is processed through PCI DSS-compliant payment processors and is never stored on our servers. While we strive to protect your data, no method of electronic transmission or storage is 100% secure."
          }
        ]
      },
      {
        "title": "5. Your Rights & Choices",
        "icon": "gavel",
        "content": [
          {
            "subtitle": "Access & Correction",
            "text": "You can access, update, or correct your personal information through your account settings at any time."
          },
          {
            "subtitle": "Deletion",
            "text": "You may request deletion of your account and personal data by contacting our support team. We will process your request within 30 days, subject to any legal retention requirements."
          },
          {
            "subtitle": "Communication Preferences",
            "text": "You can opt out of promotional emails at any time by clicking the unsubscribe link. Note that you will still receive transactional notifications related to your errands."
          }
        ]
      },
      {
        "title": "6. Data Retention",
        "icon": "history",
        "content": [
          {
            "subtitle": "",
            "text": "We retain your personal information for as long as your account is active or as needed to provide services. After account deletion, we may retain certain information for up to 90 days for fraud prevention and legal compliance. Transaction records may be retained for up to 7 years as required by Nigerian tax and financial regulations."
          }
        ]
      },
      {
        "title": "7. Children's Privacy",
        "icon": "child_care",
        "content": [
          {
            "subtitle": "",
            "text": "Errand is not intended for children under 18. We do not knowingly collect personal information from minors. If we learn that we have collected information from a child under 18, we will promptly delete it."
          }
        ]
      },
      {
        "title": "8. Contact Us",
        "icon": "contact_support",
        "content": [
          {
            "subtitle": "",
            "text": "If you have questions or concerns about this Privacy Policy or our data practices, please contact us at privacy@errand.com or write to us at Errand, 123 Abak Road, Uyo, Akwa Ibom State, Nigeria."
          }
        ]
      }
    ]
  }
} as const;
