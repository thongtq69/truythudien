import 'react-native-gesture-handler';
import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { AuthProvider, useAuth } from './src/context/AuthContext';
import { SettingsProvider } from './src/context/SettingsContext';
import LoginScreen from './src/screens/LoginScreen';
import CalculatorScreen from './src/screens/CalculatorScreen';
import HistoryScreen from './src/screens/HistoryScreen';
import LegalSearchScreen from './src/screens/LegalSearchScreen';
import AdminScreen from './src/screens/AdminScreen';
import { Colors } from './src/theme/colors';
import { Calculator, History, Search, ShieldAlert, LogOut } from 'lucide-react-native';
import { TouchableOpacity, View, ActivityIndicator, Text } from 'react-native';

const Tab = createBottomTabNavigator();

function MainTabs() {
  const { user, logout } = useAuth();

  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: Colors.primary,
        tabBarInactiveTintColor: Colors.textSecondary,
        headerShown: false,
        tabBarStyle: {
          backgroundColor: Colors.white,
          borderTopWidth: 1,
          borderTopColor: '#eee',
          height: 60,
          paddingBottom: 8,
          paddingTop: 8,
        },
        tabBarLabelStyle: {
          fontSize: 10,
          fontWeight: '500',
        }
      }}
    >
      <Tab.Screen
        name="Calculator"
        component={CalculatorScreen}
        options={{
          title: 'Tính toán',
          tabBarIcon: ({ color }) => <Calculator size={24} color={color} />
        }}
      />
      <Tab.Screen
        name="Search"
        component={LegalSearchScreen}
        options={{
          title: 'Tra cứu',
          tabBarIcon: ({ color }) => <Search size={24} color={color} />
        }}
      />
      <Tab.Screen
        name="History"
        component={HistoryScreen}
        options={{
          title: 'Lịch sử',
          tabBarIcon: ({ color }) => <History size={24} color={color} />
        }}
      />
      {user?.isAdmin === true && (
        <Tab.Screen
          name="Admin"
          component={AdminScreen}
          options={{
            title: 'Hệ thống',
            tabBarIcon: ({ color }) => <ShieldAlert size={24} color={color} />
          }}
        />
      )}
    </Tab.Navigator>
  );
}

function NavigationRoot() {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return (
      <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: Colors.background }}>
        <ActivityIndicator size="large" color={Colors.primary} />
        <Text style={{ marginTop: 12, color: Colors.textSecondary }}>Đang tải ứng dụng...</Text>
      </View>
    );
  }

  return (
    <NavigationContainer>
      {isAuthenticated ? <MainTabs /> : <LoginScreen />}
    </NavigationContainer>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <SettingsProvider>
        <NavigationRoot />
      </SettingsProvider>
    </AuthProvider>
  );
}
