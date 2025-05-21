import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DrCopilotLogo extends StatelessWidget {
  final double? width;
  final double? height;

  const DrCopilotLogo({Key? key, this.width, this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String svgString = '''
<svg viewBox="0 0 300 150" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="tealGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#20B2AA;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#008B8B;stop-opacity:1" />
    </linearGradient>
    <linearGradient id="lightTeal" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#5DADE2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#48CAE4;stop-opacity:1" />
    </linearGradient>
    <radialGradient id="glowGradient" cx="50%" cy="50%" r="50%">
      <stop offset="0%" style="stop-color:#48CAE4;stop-opacity:0.4" />
      <stop offset="100%" style="stop-color:#20B2AA;stop-opacity:0" />
    </radialGradient>
  </defs>
  
  <!-- Medical Clipboard with Digital/Circuit Elements -->
  <g transform="translate(20, 20)">
    <!-- Clipboard base -->
    <rect x="95" y="25" width="70" height="90" rx="5" fill="url(#tealGradient)"/>
    <rect x="100" y="30" width="60" height="80" rx="3" fill="#ffffff"/>
    
    <!-- Clipboard clip -->
    <rect x="120" y="20" width="20" height="15" rx="3" fill="#008B8B"/>
    <rect x="123" y="23" width="14" height="9" rx="2" fill="url(#lightTeal)"/>
    
    <!-- Digital lines on clipboard -->
    <line x1="105" y1="40" x2="155" y2="40" stroke="#5DADE2" stroke-width="2"/>
    <line x1="105" y1="50" x2="140" y2="50" stroke="#5DADE2" stroke-width="2"/>
    <line x1="105" y1="60" x2="150" y2="60" stroke="#5DADE2" stroke-width="2"/>
    <line x1="105" y1="70" x2="135" y2="70" stroke="#5DADE2" stroke-width="2"/>
    <line x1="105" y1="80" x2="145" y2="80" stroke="#5DADE2" stroke-width="2"/>
    <line x1="105" y1="90" x2="155" y2="90" stroke="#5DADE2" stroke-width="2"/>
    
    <!-- Circuit nodes around clipboard -->
    <circle cx="75" cy="45" r="3" fill="#20B2AA"/>
    <circle cx="75" cy="45" r="5" fill="url(#glowGradient)" opacity="0.4"/>
    
    <circle cx="185" cy="55" r="3" fill="#48CAE4"/>
    <circle cx="185" cy="55" r="5" fill="url(#glowGradient)" opacity="0.4"/>
    
    <circle cx="80" cy="85" r="2.5" fill="#5DADE2"/>
    <circle cx="180" cy="75" r="2.5" fill="#20B2AA"/>
    
    <!-- Circuit connections -->
    <line x1="78" y1="45" x2="95" y2="45" stroke="#5DADE2" stroke-width="1.5" opacity="0.8"/>
    <line x1="165" y1="55" x2="182" y2="55" stroke="#5DADE2" stroke-width="1.5" opacity="0.8"/>
    <line x1="82" y1="83" x2="95" y2="75" stroke="#5DADE2" stroke-width="1.5" opacity="0.6"/>
    <line x1="165" y1="75" x2="177" y2="75" stroke="#5DADE2" stroke-width="1.5" opacity="0.6"/>
    
    <!-- Additional tech elements -->
    <circle cx="130" cy="15" r="1.5" fill="#48CAE4" opacity="0.7"/>
    <line x1="130" y1="15" x2="130" y2="20" stroke="#5DADE2" stroke-width="1" opacity="0.6"/>
    
    <!-- "Dr Copilot" text on same line -->
    <text x="85" y="140" font-family="Arial, sans-serif" font-size="22" font-weight="bold" fill="url(#tealGradient)">Dr Copilot</text>
  </g>
</svg>
''';

    return SvgPicture.string(
      svgString,
      width: width,
      height: height,
      fit: BoxFit.contain,
    );
  }
}