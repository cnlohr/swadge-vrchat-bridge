using UdonSharp;
using UnityEngine;

namespace DrakenStark
{
	[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]
	public class HitManager : UdonSharpBehaviour
	{
		[SerializeField] private EnemyLogic _enemyLogic = null;
		
		public void _cannonHit(int cannon, int level)
		{
			SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Cannon_" + cannon + "_" + level);
		}
		
		public void _swadgeHit(int swadge)
		{
			SendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, "Swadge_" + swadge);
		}

		public void Cannon_1_0() { _enemyLogic._hit(1,0); }
		public void Cannon_1_1() { _enemyLogic._hit(1,1); }
		public void Cannon_1_2() { _enemyLogic._hit(1,2); }
		public void Cannon_1_3() { _enemyLogic._hit(1,3); }
		public void Cannon_2_0() { _enemyLogic._hit(2,0); }
		public void Cannon_2_1() { _enemyLogic._hit(2,1); }
		public void Cannon_2_2() { _enemyLogic._hit(2,2); }
		public void Cannon_2_3() { _enemyLogic._hit(2,3); }
		public void Cannon_3_0() { _enemyLogic._hit(3,0); }
		public void Cannon_3_1() { _enemyLogic._hit(3,1); }
		public void Cannon_3_2() { _enemyLogic._hit(3,2); }
		public void Cannon_3_3() { _enemyLogic._hit(3,3); }
		public void Cannon_4_0() { _enemyLogic._hit(4,0); }
		public void Cannon_4_1() { _enemyLogic._hit(4,1); }
		public void Cannon_4_2() { _enemyLogic._hit(4,2); }
		public void Cannon_4_3() { _enemyLogic._hit(4,3); }
		public void Cannon_5_0() { _enemyLogic._hit(5,0); }
		public void Cannon_5_1() { _enemyLogic._hit(5,1); }
		public void Cannon_5_2() { _enemyLogic._hit(5,2); }
		public void Cannon_5_3() { _enemyLogic._hit(5,3); }
		public void Cannon_6_0() { _enemyLogic._hit(6,0); }
		public void Cannon_6_1() { _enemyLogic._hit(6,1); }
		public void Cannon_6_2() { _enemyLogic._hit(6,2); }
		public void Cannon_6_3() { _enemyLogic._hit(6,3); }
		public void Cannon_7_0() { _enemyLogic._hit(7,0); }
		public void Cannon_7_1() { _enemyLogic._hit(7,1); }
		public void Cannon_7_2() { _enemyLogic._hit(7,2); }
		public void Cannon_7_3() { _enemyLogic._hit(7,3); }
		public void Cannon_8_0() { _enemyLogic._hit(8,0); }
		public void Cannon_8_1() { _enemyLogic._hit(8,1); }
		public void Cannon_8_2() { _enemyLogic._hit(8,2); }
		public void Cannon_8_3() { _enemyLogic._hit(8,3); }
		public void Cannon_9_0() { _enemyLogic._hit(9,0); }
		public void Cannon_9_1() { _enemyLogic._hit(9,1); }
		public void Cannon_9_2() { _enemyLogic._hit(9,2); }
		public void Cannon_9_3() { _enemyLogic._hit(9,3); }
		public void Cannon_10_0() { _enemyLogic._hit(10,0); }
		public void Cannon_10_1() { _enemyLogic._hit(10,1); }
		public void Cannon_10_2() { _enemyLogic._hit(10,2); }
		public void Cannon_10_3() { _enemyLogic._hit(10,3); }
		public void Cannon_11_0() { _enemyLogic._hit(11,0); }
		public void Cannon_11_1() { _enemyLogic._hit(11,1); }
		public void Cannon_11_2() { _enemyLogic._hit(11,2); }
		public void Cannon_11_3() { _enemyLogic._hit(11,3); }
		public void Cannon_12_0() { _enemyLogic._hit(12,0); }
		public void Cannon_12_1() { _enemyLogic._hit(12,1); }
		public void Cannon_12_2() { _enemyLogic._hit(12,2); }
		public void Cannon_12_3() { _enemyLogic._hit(12,3); }
		public void Cannon_13_0() { _enemyLogic._hit(13,0); }
		public void Cannon_13_1() { _enemyLogic._hit(13,1); }
		public void Cannon_13_2() { _enemyLogic._hit(13,2); }
		public void Cannon_13_3() { _enemyLogic._hit(13,3); }
		public void Cannon_14_0() { _enemyLogic._hit(14,0); }
		public void Cannon_14_1() { _enemyLogic._hit(14,1); }
		public void Cannon_14_2() { _enemyLogic._hit(14,2); }
		public void Cannon_14_3() { _enemyLogic._hit(14,3); }
		public void Cannon_15_0() { _enemyLogic._hit(15,0); }
		public void Cannon_15_1() { _enemyLogic._hit(15,1); }
		public void Cannon_15_2() { _enemyLogic._hit(15,2); }
		public void Cannon_15_3() { _enemyLogic._hit(15,3); }
		public void Cannon_16_0() { _enemyLogic._hit(16,0); }
		public void Cannon_16_1() { _enemyLogic._hit(16,1); }
		public void Cannon_16_2() { _enemyLogic._hit(16,2); }
		public void Cannon_16_3() { _enemyLogic._hit(16,3); }
		public void Cannon_17_0() { _enemyLogic._hit(17,0); }
		public void Cannon_17_1() { _enemyLogic._hit(17,1); }
		public void Cannon_17_2() { _enemyLogic._hit(17,2); }
		public void Cannon_17_3() { _enemyLogic._hit(17,3); }
		public void Cannon_18_0() { _enemyLogic._hit(18,0); }
		public void Cannon_18_1() { _enemyLogic._hit(18,1); }
		public void Cannon_18_2() { _enemyLogic._hit(18,2); }
		public void Cannon_18_3() { _enemyLogic._hit(18,3); }
		public void Cannon_19_0() { _enemyLogic._hit(19,0); }
		public void Cannon_19_1() { _enemyLogic._hit(19,1); }
		public void Cannon_19_2() { _enemyLogic._hit(19,2); }
		public void Cannon_19_3() { _enemyLogic._hit(19,3); }
		public void Cannon_20_0() { _enemyLogic._hit(20,0); }
		public void Cannon_20_1() { _enemyLogic._hit(20,1); }
		public void Cannon_20_2() { _enemyLogic._hit(20,2); }
		public void Cannon_20_3() { _enemyLogic._hit(20,3); }
		public void Cannon_21_0() { _enemyLogic._hit(21,0); }
		public void Cannon_21_1() { _enemyLogic._hit(21,1); }
		public void Cannon_21_2() { _enemyLogic._hit(21,2); }
		public void Cannon_21_3() { _enemyLogic._hit(21,3); }
		public void Cannon_22_0() { _enemyLogic._hit(22,0); }
		public void Cannon_22_1() { _enemyLogic._hit(22,1); }
		public void Cannon_22_2() { _enemyLogic._hit(22,2); }
		public void Cannon_22_3() { _enemyLogic._hit(22,3); }
		public void Cannon_23_0() { _enemyLogic._hit(23,0); }
		public void Cannon_23_1() { _enemyLogic._hit(23,1); }
		public void Cannon_23_2() { _enemyLogic._hit(23,2); }
		public void Cannon_23_3() { _enemyLogic._hit(23,3); }
		public void Cannon_24_0() { _enemyLogic._hit(24,0); }
		public void Cannon_24_1() { _enemyLogic._hit(24,1); }
		public void Cannon_24_2() { _enemyLogic._hit(24,2); }
		public void Cannon_24_3() { _enemyLogic._hit(24,3); }
		public void Swadge_26() { _enemyLogic._hit(26); }
		public void Swadge_27() { _enemyLogic._hit(27); }
		public void Swadge_28() { _enemyLogic._hit(28); }
		public void Swadge_29() { _enemyLogic._hit(29); }
		public void Swadge_30() { _enemyLogic._hit(30); }
		public void Swadge_31() { _enemyLogic._hit(31); }
		public void Swadge_32() { _enemyLogic._hit(32); }
		public void Swadge_33() { _enemyLogic._hit(33); }
		public void Swadge_34() { _enemyLogic._hit(34); }
		public void Swadge_35() { _enemyLogic._hit(35); }
		public void Swadge_36() { _enemyLogic._hit(36); }
		public void Swadge_37() { _enemyLogic._hit(37); }
		public void Swadge_38() { _enemyLogic._hit(38); }
		public void Swadge_39() { _enemyLogic._hit(39); }
		public void Swadge_40() { _enemyLogic._hit(40); }
		public void Swadge_41() { _enemyLogic._hit(41); }
		public void Swadge_42() { _enemyLogic._hit(42); }
		public void Swadge_43() { _enemyLogic._hit(43); }
		public void Swadge_44() { _enemyLogic._hit(44); }
		public void Swadge_45() { _enemyLogic._hit(45); }
		public void Swadge_46() { _enemyLogic._hit(46); }
		public void Swadge_47() { _enemyLogic._hit(47); }
		public void Swadge_48() { _enemyLogic._hit(48); }
		public void Swadge_49() { _enemyLogic._hit(49); }
		public void Swadge_50() { _enemyLogic._hit(50); }
		public void Swadge_51() { _enemyLogic._hit(51); }
		public void Swadge_52() { _enemyLogic._hit(52); }
		public void Swadge_53() { _enemyLogic._hit(53); }
		public void Swadge_54() { _enemyLogic._hit(54); }
		public void Swadge_55() { _enemyLogic._hit(55); }
		public void Swadge_56() { _enemyLogic._hit(56); }
		public void Swadge_57() { _enemyLogic._hit(57); }
		public void Swadge_58() { _enemyLogic._hit(58); }
		public void Swadge_59() { _enemyLogic._hit(59); }
		public void Swadge_60() { _enemyLogic._hit(60); }
		public void Swadge_61() { _enemyLogic._hit(61); }
		public void Swadge_62() { _enemyLogic._hit(62); }
		public void Swadge_63() { _enemyLogic._hit(63); }
		public void Swadge_64() { _enemyLogic._hit(64); }
		public void Swadge_65() { _enemyLogic._hit(65); }
		public void Swadge_66() { _enemyLogic._hit(66); }
		public void Swadge_67() { _enemyLogic._hit(67); }
		public void Swadge_68() { _enemyLogic._hit(68); }
		public void Swadge_69() { _enemyLogic._hit(69); }
		public void Swadge_70() { _enemyLogic._hit(70); }
		public void Swadge_71() { _enemyLogic._hit(71); }
		public void Swadge_72() { _enemyLogic._hit(72); }
		public void Swadge_73() { _enemyLogic._hit(73); }
		public void Swadge_74() { _enemyLogic._hit(74); }
		public void Swadge_75() { _enemyLogic._hit(75); }
		public void Swadge_76() { _enemyLogic._hit(76); }
		public void Swadge_77() { _enemyLogic._hit(77); }
		public void Swadge_78() { _enemyLogic._hit(78); }
		public void Swadge_79() { _enemyLogic._hit(79); }
		public void Swadge_80() { _enemyLogic._hit(80); }
		public void Swadge_81() { _enemyLogic._hit(81); }
		public void Swadge_82() { _enemyLogic._hit(82); }
		public void Swadge_83() { _enemyLogic._hit(83); }
		public void Swadge_84() { _enemyLogic._hit(84); }
		public void Swadge_85() { _enemyLogic._hit(85); }
		public void Swadge_86() { _enemyLogic._hit(86); }
		public void Swadge_87() { _enemyLogic._hit(87); }
		public void Swadge_88() { _enemyLogic._hit(88); }
		public void Swadge_89() { _enemyLogic._hit(89); }
		public void Swadge_90() { _enemyLogic._hit(90); }
		public void Swadge_91() { _enemyLogic._hit(91); }
		public void Swadge_92() { _enemyLogic._hit(92); }
		public void Swadge_93() { _enemyLogic._hit(93); }
		public void Swadge_94() { _enemyLogic._hit(94); }
		public void Swadge_95() { _enemyLogic._hit(95); }
		public void Swadge_96() { _enemyLogic._hit(96); }
		public void Swadge_97() { _enemyLogic._hit(97); }
		public void Swadge_98() { _enemyLogic._hit(98); }
		public void Swadge_99() { _enemyLogic._hit(99); }
		public void Swadge_100() { _enemyLogic._hit(100); }
		public void Swadge_101() { _enemyLogic._hit(101); }
		public void Swadge_102() { _enemyLogic._hit(102); }
		public void Swadge_103() { _enemyLogic._hit(103); }
		public void Swadge_104() { _enemyLogic._hit(104); }
		public void Swadge_105() { _enemyLogic._hit(105); }
		public void Swadge_106() { _enemyLogic._hit(106); }
		public void Swadge_107() { _enemyLogic._hit(107); }
		public void Swadge_108() { _enemyLogic._hit(108); }
		public void Swadge_109() { _enemyLogic._hit(109); }
		public void Swadge_110() { _enemyLogic._hit(110); }
		public void Swadge_111() { _enemyLogic._hit(111); }
		public void Swadge_112() { _enemyLogic._hit(112); }
		public void Swadge_113() { _enemyLogic._hit(113); }
		public void Swadge_114() { _enemyLogic._hit(114); }
		public void Swadge_115() { _enemyLogic._hit(115); }
	}
}