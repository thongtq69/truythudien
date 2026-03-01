import React, { useState } from 'react';
import { StyleSheet, View, Text, TouchableOpacity, LayoutAnimation, Platform, UIManager } from 'react-native';
import { ChevronRight, ChevronDown, AlertTriangle } from 'lucide-react-native';
import { Colors } from '../theme/colors';

if (Platform.OS === 'android') {
    if (UIManager.setLayoutAnimationEnabledExperimental) {
        UIManager.setLayoutAnimationEnabledExperimental(true);
    }
}

const Collapsible = ({ label, children, isWarning = false, expandedDefault = false }) => {
    const [isExpanded, setIsExpanded] = useState(expandedDefault);

    const toggle = () => {
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setIsExpanded(!isExpanded);
    };

    return (
        <View style={styles.container}>
            <TouchableOpacity onPress={toggle} style={styles.header}>
                <Text style={[styles.label, isWarning && { color: Colors.danger }]}>{label}</Text>
                <View style={styles.headerRight}>
                    {isWarning && <AlertTriangle size={14} color={Colors.danger} style={{ marginRight: 8 }} />}
                    {isExpanded ? <ChevronDown size={18} color={Colors.textSecondary} /> : <ChevronRight size={18} color={Colors.textSecondary} />}
                </View>
            </TouchableOpacity>
            {isExpanded && <View style={styles.content}>{children}</View>}
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        marginVertical: 4,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 8,
    },
    label: {
        fontSize: 13,
        color: Colors.textSecondary,
    },
    headerRight: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    content: {
        paddingTop: 4,
        paddingBottom: 8,
    },
});

export default Collapsible;
