# Player Commands & Interactions Guide

Complete guide to player interactions and commands for Country Road RP: Reckoning.

## 🎮 Key Bindings

| Key | Command | Description |
|-----|---------|-------------|
| **F6** | Main Menu | Opens the comprehensive Reckoning interface |
| **F7** | Status Check | Quick personal status report |
| **F8** | Radio Check | Quick resistance radio status |

*Note: Key bindings can be customized in FiveM settings under Key Bindings > FiveM*

## 💬 Chat Commands

### Personal Status Commands

#### `/suspicion`
- **Description**: Check your current suspicion level
- **Usage**: `/suspicion`
- **Output**: Shows suspicion percentage and risk level
- **Example**: `Suspicion Level: 45% (MODERATE)`

#### `/clearance`
- **Description**: Check your security clearance level
- **Usage**: `/clearance`
- **Output**: Shows clearance level and access permissions
- **Example**: `Clearance: Level 2 (Standard Access)`

#### `/resistance`
- **Description**: Access resistance communications menu
- **Usage**: `/resistance`
- **Requirements**: None (but monitored by security)
- **Features**:
  - Tune to resistance frequency
  - Check signal strength
  - Review recent broadcasts

#### `/tunnel`
- **Description**: Get tunnel access information
- **Usage**: `/tunnel`
- **Requirements**: Proximity to tunnel entrance
- **Features**:
  - Check nearest tunnel entrance
  - Verify access permissions
  - Enter tunnel network (if authorized)

## 🖥️ Main Interface Menu (F6)

### Personal Status Panel
Displays real-time information about your character:
- **Clearance Level**: Security access level (0-4)
- **Suspicion Level**: How much attention you've attracted (0-100%)
- **Job Position**: Current employment and rank
- **Security Status**: Overall risk assessment

### Access Control Section
- **📍 Restricted Zones**: Check nearby secured areas
- **🕳️ Tunnel Access**: TRENCHGLASS tunnel network entry

### Communications Section  
- **📻 Resistance Net**: Connect to resistance frequency (455.550)
- **📡 Signal Check**: Test radio signal quality
- **📋 Recent Broadcasts**: Review resistance communications

### Intelligence Section
- **👤 Report NPC**: Report suspicious individuals
- **📊 Status Report**: Detailed personal status

## 🔐 Security Clearance Levels

| Level | Access | Description |
|-------|---------|-------------|
| **0** | No Access | Standard civilian, no special permissions |
| **1** | Basic | Low-level employee access |
| **2** | Standard | Mid-level access, tunnel entry permitted |
| **3** | High | Senior access, restricted area entry |
| **4** | Maximum | Full access, all systems available |

## ⚠️ Suspicion System

### Suspicion Levels
- **0-24%**: 🟢 **Minimal Risk** - Standard monitoring
- **25-49%**: 🟡 **Low Risk** - Routine surveillance  
- **50-74%**: 🟠 **Moderate Risk** - Enhanced monitoring
- **75-89%**: 🔴 **High Risk** - Active surveillance
- **90-100%**: 🚨 **Critical Threat** - Immediate response

### Activities That Increase Suspicion
- Accessing resistance radio frequencies
- Unauthorized tunnel access attempts
- Reporting false information about NPCs
- Loitering in restricted areas
- Repeated failed clearance checks

### Activities That Decrease Suspicion
- Reporting legitimate suspicious NPCs
- Following proper access protocols
- Maintaining job responsibilities
- Cooperating with security

## 📻 Resistance Radio System

### Main Frequency: 455.550 MHz
- Primary resistance communication channel
- Monitored by corporate security
- Signal strength varies by location

### Radio Commands
- **Tune**: Connect to resistance frequency
- **Signal Check**: Test current signal quality (60-95%)
- **Recent Broadcasts**: Review last 5 resistance messages

### Signal Quality Factors
- **Location**: Open areas have better signal
- **Elevation**: Underground locations have poor signal
- **Weather**: Can affect signal clarity
- **Equipment**: Radio quality impacts reception

## 🕳️ TRENCHGLASS Tunnel System

### Access Requirements
1. **Job Clearance**: Must be Merryweather or Northbridge employee
2. **Rank Requirements**:
   - Merryweather: Operative, Agent, or Commander
   - Northbridge: Analyst, Executive, or Director  
3. **Security Clearance**: Level 2 or higher
4. **Proximity**: Must be within tunnel entrance radius

### Tunnel Features
- **GPS Blackout**: Navigation disabled underground
- **Environmental Effects**: Fog and reduced visibility
- **Access Logging**: All entries/exits recorded
- **Emergency Protocols**: Automatic lockdown capabilities

## 👥 NPC Interaction System

### Reporting Suspicious NPCs
1. Use `/resistance` menu or F6 interface
2. Select "Report NPC" option
3. Target suspicious individual
4. Submit report for investigation

### Report Outcomes
- **Correct Report**: Reduce suspicion (-5%), earn reward ($50)
- **False Report**: Increase suspicion (+2%), no reward
- **Investigation**: All reports logged and tracked

### Identifying Suspicious NPCs
Look for:
- Unusual behavior patterns
- Loitering in sensitive areas
- Inappropriate clothing for location
- Nervous or evasive behavior

## 🚨 Emergency Procedures

### During Lockdowns
1. Remain calm and follow instructions
2. Move to designated safe areas
3. Avoid restricted zones
4. Comply with security personnel
5. Do not use resistance communications

### Security Alerts
- **Level 1**: Routine security check
- **Level 2**: Enhanced monitoring active
- **Level 3**: Area restrictions in effect
- **Level 4**: Full lockdown, comply immediately

## 🎯 Tips for Roleplay

### For Resistance Members
- Use coded language in communications
- Avoid obvious suspicious behavior
- Build trust slowly with other players
- Gather intelligence carefully
- Maintain cover identity

### For Corporate Employees  
- Follow proper security protocols
- Report suspicious activities
- Maintain professional appearance
- Use proper clearance channels
- Support company objectives

### For Civilians
- Stay aware of security alerts
- Avoid restricted areas
- Cooperate with authorities
- Report unusual activities
- Maintain low profile

## 🔧 Admin Commands (Admin Only)

### `/giveclearance [playerid] [level]`
- **Description**: Set player's clearance level
- **Usage**: `/giveclearance 1 3`
- **Parameters**: 
  - `playerid`: Target player's server ID
  - `level`: Clearance level (0-4)

### `/setsuspicion [playerid] [level]`
- **Description**: Set player's suspicion level
- **Usage**: `/setsuspicion 1 75`
- **Parameters**:
  - `playerid`: Target player's server ID  
  - `level`: Suspicion percentage (0-100)

## 📊 Status Monitoring

Players can monitor their status through:
- **Real-time HUD**: Key information displayed
- **Chat Commands**: Quick status checks
- **Main Interface**: Comprehensive status panel
- **Notifications**: Automatic updates on changes

## 🔍 Troubleshooting

### Menu Won't Open
- Check if F6 key is bound correctly
- Ensure resource is running properly
- Try `/restart countryroadrp-reckoning`

### Radio Issues
- Verify pma-voice is installed and running
- Check if frequency is correct (455.550)
- Test signal strength in different locations

### Access Denied
- Confirm job and rank requirements
- Check clearance level with `/clearance`
- Ensure proximity to access point

### Status Not Updating
- Try `/refreshstatus` if available
- Restart resource if issues persist
- Contact admin for database sync

---

## 🎭 Roleplay Guidelines

Remember that Country Road RP: Reckoning is designed for immersive roleplay:

- **Stay in Character**: Make decisions based on your character's knowledge
- **Maintain Immersion**: Use proper terminology and procedures
- **Respect the Narrative**: Support the overarching storyline
- **Collaborate**: Work with other players to create engaging scenarios
- **Follow Rules**: Adhere to server rules and admin guidance

*For technical support or roleplay questions, contact the Country Road RP administration team.*
