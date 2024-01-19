using UnityEngine;
using UnityEditor;
using UdonSharpEditor;
using VRC;

namespace DrakenStark
{
    [CustomEditor(typeof(DataManager))]
    public class DataManagerEditor : Editor
    {

        DataManager dataManager = null;

        SerializedProperty swadgeIntegration = null;
        SerializedProperty cannons = null;
        SerializedProperty pickups = null;
        SerializedProperty cannonColliders = null;
        SerializedProperty cannonSync = null;
        SerializedProperty vRCProjectiles = null;
        SerializedProperty enemyLogics = null;
        SerializedProperty enemyColliders = null;
        SerializedProperty enemyTargets = null;
        SerializedProperty swadgeShips = null;
        SerializedProperty swadgeShipTrans = null;
        SerializedProperty swadgeProjectiles = null;
        SerializedProperty aboveCannons = null;
        SerializedProperty aboveEnemyTargets = null;
        SerializedProperty aboveSwadgeShips = null;

        int levels = 4;
        string scriptName = "HitManager";

        private void OnEnable()
        {
            dataManager = (DataManager)target;

            swadgeIntegration = serializedObject.FindProperty("_swadgeIntegration");
            cannons = serializedObject.FindProperty("_cannons");
            pickups = serializedObject.FindProperty("_pickups");
            cannonColliders = serializedObject.FindProperty("_cannonColliders");
            cannonSync = serializedObject.FindProperty("_cannonSync");
            vRCProjectiles = serializedObject.FindProperty("_vRCProjectiles");
            enemyLogics = serializedObject.FindProperty("_enemyLogics");
            enemyColliders = serializedObject.FindProperty("_enemyColliders");
            enemyTargets = serializedObject.FindProperty("_enemyTargets");
            swadgeShips = serializedObject.FindProperty("_swadgeShips");
            swadgeShipTrans = serializedObject.FindProperty("_swadgeShipTrans");
            swadgeProjectiles = serializedObject.FindProperty("_swadgeProjectiles");
            aboveCannons = serializedObject.FindProperty("_aboveCannonID");
            aboveEnemyTargets = serializedObject.FindProperty("_aboveEnemyTargetID");
            aboveSwadgeShips = serializedObject.FindProperty("_aboveSwadgeShipID");
        }

        public override void OnInspectorGUI()
        {
            if (UdonSharpGUI.DrawDefaultUdonSharpBehaviourHeader(target)) return;

            EditorGUILayout.HelpBox("Swadge Limits:\n" +
                "VRC Projectiles = 0 to 239 (240)\n" +
                "Cannons = 0 to 23       (24)\n" +
                "Swadges = 0 to 102     (103)\n" +
                "Enemies = 0 to 47       (96)", MessageType.Info);

            if (GUILayout.Button("Find All Relevant Objects"))
            {
                byte targetID = 0; //Will not actually assign zero, zero is reserved for the ID of none.
                //Find all of each kind of item in the scene

                SwadgeIntegration[] AllSwadgeIntegration = FindObjectsOfType<SwadgeIntegration>(true);
                if (AllSwadgeIntegration.Length > 0 && AllSwadgeIntegration.Length < 2)
                {
                    swadgeIntegration.objectReferenceValue = AllSwadgeIntegration[0];
                }
                else
                {
                    Debug.LogWarning("There should be one SwadgeIntegration script! Either remove any extras or create one if there is none.");
                }

                SwadgeCannonSync[] AllCannonSync = FindObjectsOfType<SwadgeCannonSync>(true);
                if (AllCannonSync.Length > 0 && AllCannonSync.Length < 2)
                {
                    cannonSync.objectReferenceValue = AllCannonSync[0];
                    AllCannonSync[0]._setup(AllSwadgeIntegration[0]);
                    AllCannonSync[0].MarkDirty();
                }
                else
                {
                    Debug.LogWarning("There should be one CannonSync script! Either remove any extras or create one if there is none.");
                }

                //string debugString = "";
                try
                {
                    vRCProjectiles.arraySize = 0;
                    Projectile[] NewProjectiles = new Projectile[0];
                    int projectileElement = 0;

                    //Setup Cannons
                    HandCannon[] AllCannons = FindObjectsOfType<HandCannon>(true);
                    cannons.arraySize = AllCannons.Length;
                    pickups.arraySize = AllCannons.Length;
                    cannonColliders.arraySize = AllCannons.Length;
                    Transform[] cannonTransforms = new Transform[AllCannons.Length];
                    for (byte i = 0; i < AllCannons.Length; i++)
                    {
                        cannons.GetArrayElementAtIndex(i).objectReferenceValue = AllCannons[i];
                        pickups.GetArrayElementAtIndex(i).objectReferenceValue = AllCannons[i]._getPickup();
                        cannonColliders.GetArrayElementAtIndex(i).objectReferenceValue = AllCannons[i]._getCollider();

                        //Find all Projectiles for this.
                        NewProjectiles = AllCannons[i].transform.parent.gameObject.GetComponentsInChildren<Projectile>(true);
                        vRCProjectiles.arraySize += NewProjectiles.Length;
                        for (int n = 0; n < NewProjectiles.Length; n++)
                        {
                            vRCProjectiles.GetArrayElementAtIndex(projectileElement).objectReferenceValue = NewProjectiles[n];
                            NewProjectiles[n]._setup(dataManager, projectileElement, targetID);
                            NewProjectiles[n].MarkDirty();

                            projectileElement++;
                        }


                        AllCannons[i]._setup(dataManager, ++targetID, NewProjectiles);
                        cannonTransforms[i] = AllCannons[i].transform;

                        //Setup Respawn Point if it doesn't exist yet.
                        if (AllCannons[i]._getRespawnPoint() == null)
                        {
                            GameObject newRespawnPoint = new GameObject();
                            newRespawnPoint.name = AllCannons[i].transform.parent.name + " Respawn";
                            newRespawnPoint.transform.SetParent(AllCannons[i].transform.parent.parent);
                            newRespawnPoint.transform.position = AllCannons[i].transform.parent.position;
                            newRespawnPoint.transform.rotation = AllCannons[i].transform.parent.rotation;
                            //newRespawnPoint.transform.SetSiblingIndex(AllCannons[i].transform.GetSiblingIndex() + 1);
                            AllCannons[i]._setRespawnPoint(newRespawnPoint.transform);
                        }
                        AllCannons[i].MarkDirty();
                    }
                    AllCannonSync[0]._setupCannons(AllCannons);
                    AllCannonSync[0].enabled = false;
                    AllCannonSync[0].MarkDirty();

                    /*
                    Projectile[] AllProjectiles = FindObjectsOfType<Projectile>(true);
                    projectiles.arraySize = AllProjectiles.Length;
                    for (int i = 0; i < AllProjectiles.Length; i++)
                    {
                        projectiles.GetArrayElementAtIndex(i).objectReferenceValue = AllProjectiles[i].transform;
                        AllProjectiles[i]._setup(dataManager, i);
                        AllProjectiles[i].MarkDirty();
                    }*/

                    //Setup Enemy Logics
                    EnemyLogic[] AllEnemyLogics = FindObjectsOfType<EnemyLogic>(true);
                    enemyLogics.arraySize = AllEnemyLogics.Length;
                    enemyColliders.arraySize = AllEnemyLogics.Length;
                    for (int i = 0; i < AllEnemyLogics.Length; i++)
                    {
                        enemyLogics.GetArrayElementAtIndex(i).objectReferenceValue = AllEnemyLogics[i];
                        enemyColliders.GetArrayElementAtIndex(i).objectReferenceValue = AllEnemyLogics[i]._getCollider();
                        AllEnemyLogics[i]._setup(dataManager, i);
                        AllEnemyLogics[i].MarkDirty();
                    }

                    //Setup Enemy Targets
                    EnemyTarget[] AllEnemyTargets = FindObjectsOfType<EnemyTarget>(true);
                    enemyTargets.arraySize = AllEnemyTargets.Length;
                    SwadgeEnemyPosSync SwadgeSync = null;
                    for (int i = 0; i < AllEnemyTargets.Length; i++)
                    {
                        enemyTargets.GetArrayElementAtIndex(i).objectReferenceValue = AllEnemyTargets[i];
                        SwadgeSync = AllEnemyTargets[i].transform.parent.gameObject.GetComponentInChildren<SwadgeEnemyPosSync>(true);
                        if (SwadgeSync == null)
                        {
                            AllEnemyTargets[i]._setup(++targetID, null);
                        }
                        else
                        {
                            AllEnemyTargets[i]._setup(++targetID, SwadgeSync);
                        }
                        AllEnemyTargets[i].MarkDirty();
                    }

                    //Setup Swadge Ships
                    SwadgeShip[] AllSwadgeShips = FindObjectsOfType<SwadgeShip>(true);
                    swadgeShips.arraySize = AllSwadgeShips.Length;
                    swadgeShipTrans.arraySize = AllSwadgeShips.Length;
                    swadgeProjectiles.arraySize = 0;
                    int swadgeProjectileElement = 0;
                    for (int i = 0; i < AllSwadgeShips.Length; i++)
                    {
                        swadgeShips.GetArrayElementAtIndex(i).objectReferenceValue = AllSwadgeShips[i];
                        AllSwadgeShips[i]._setup(++targetID);
                        swadgeShipTrans.GetArrayElementAtIndex(i).objectReferenceValue = AllSwadgeShips[i].transform;
                        AllSwadgeShips[i].MarkDirty();

                        //Find all Projectiles for this.
                        NewProjectiles = AllSwadgeShips[i].transform.parent.gameObject.GetComponentsInChildren<Projectile>(true);
                        //projectiles.arraySize += NewProjectiles.Length;
                        swadgeProjectiles.arraySize += NewProjectiles.Length;
                        for (int n = 0; n < NewProjectiles.Length; n++)
                        {
                            //projectiles.GetArrayElementAtIndex(swadgeProjectileElement).objectReferenceValue = NewProjectiles[n];
                            swadgeProjectiles.GetArrayElementAtIndex(swadgeProjectileElement).objectReferenceValue = NewProjectiles[n];
                            NewProjectiles[n]._setup(dataManager, swadgeProjectileElement, targetID);
                            NewProjectiles[n].MarkDirty();

                            swadgeProjectileElement++;
                        }
                    }

                    //Setup EnemyStriders
                    EnemyStrider[] enemyStriders = FindObjectsOfType<EnemyStrider>(true);
                    for (int i = 0; i < enemyStriders.Length; i++)
                    {
                        //Find all Projectiles for this.
                        NewProjectiles = AllEnemyLogics[i].transform.parent.gameObject.GetComponentsInChildren<Projectile>(true);
                        vRCProjectiles.arraySize += NewProjectiles.Length;
                        for (int n = 0; n < NewProjectiles.Length; n++)
                        {
                            vRCProjectiles.GetArrayElementAtIndex(projectileElement).objectReferenceValue = NewProjectiles[n];
                            NewProjectiles[n]._setup(dataManager, projectileElement, targetID);
                            NewProjectiles[n].MarkDirty();

                            projectileElement++;
                        }

                        enemyStriders[i]._setup(dataManager, NewProjectiles);
                        enemyStriders[i].MarkDirty();
                        serializedObject.ApplyModifiedProperties();
                    }

                    //Setup SwadgeEnemyPosSyncs
                    SwadgeEnemyPosSync[] enemySwadgeSync = FindObjectsOfType<SwadgeEnemyPosSync>(true);
                    for (int i = 0; i < enemySwadgeSync.Length; i++)
                    {
                        enemySwadgeSync[i].enabled = false;
                        enemySwadgeSync[i]._setup(AllSwadgeIntegration[0]);
                        enemySwadgeSync[i].MarkDirty();
                        serializedObject.ApplyModifiedProperties();
                    }

                    aboveCannons.intValue = cannons.arraySize + 1;
                    aboveEnemyTargets.intValue = cannons.arraySize + enemyTargets.arraySize + 1;
                    aboveSwadgeShips.intValue = cannons.arraySize + enemyTargets.arraySize + swadgeShips.arraySize + 1;

                    if (targetID > 255)
                    {
                        Debug.LogWarning("EntityIDs is full! The number of Cannons, EnemyTargets, and SwadgeShips must be 255 or lower!");
                    }

                    Debug.LogWarning("Found " + cannons.arraySize + " Cannons, " +
                        enemyLogics.arraySize + " EnemyLogics, " + vRCProjectiles.arraySize + " Projectiles, " + enemyTargets.arraySize + " EnemyTargets, " +
                        swadgeShips.arraySize + " SwadgeShips, " + swadgeProjectiles.arraySize + " SwadgeProjectiles, and " + AllSwadgeIntegration.Length + " SwadgeIntegration(s).");
                    //Debug.LogWarning(debugString);

                    serializedObject.ApplyModifiedProperties();
                }
                catch(System.Exception err)
                {
                    Debug.LogError(err);
                    //Debug.LogWarning(debugString);
                    serializedObject.ApplyModifiedProperties();
                }
            }

            //Mob Logic Collision Registration
            levels = EditorGUILayout.IntField("Total Projectile Types:", levels);
            scriptName = EditorGUILayout.TextField("Script Name", scriptName);

            if (GUILayout.Button("Generate Functions"))
            {
                string path = "Assets/DrakenAssets/GeneratedFunctions/" + scriptName + ".cs";

                try
                {
                    AssetDatabase.Refresh();
                    Debug.LogWarning(AssetDatabase.FindAssets("DataManager.cs"));

                    Debug.LogWarning("Writing " + System.IO.Path.GetExtension(path) + " file to " + path);

                    //Prefix goes here.
                    string fullFile = "using UdonSharp;\n" +
                        "using UnityEngine;\n" +
                        "\n" +
                        "namespace DrakenStark\n" +
                        "{\n" +
                        "\t[UdonBehaviourSyncMode(BehaviourSyncMode.Manual)]\n" +
                        "\tpublic class " + scriptName + " : UdonSharpBehaviour\n" +
                        "\t{\n" +
                        "\t\t[SerializeField] private EnemyLogic _enemyLogic = null;\n" +
                        "\t\t\n" +
                        "\t\tpublic void _cannonHit(int cannon, int level)\n" +
                        "\t\t{\n" +
                        "\t\t\tSendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, \"Cannon_\" + cannon + \"_\" + level);\n" +
                        "\t\t}\n" +
                        "\t\t\n" +
                        "\t\tpublic void _swadgeHit(int swadge)\n" +
                        "\t\t{\n" +
                        "\t\t\tSendCustomNetworkEvent(VRC.Udon.Common.Interfaces.NetworkEventTarget.All, \"Swadge_\" + swadge);\n" +
                        "\t\t}\n\n";

                    //Function Generation goes here.
                    if (cannons.arraySize > 0 && levels > 0)
                    {
                        for (int i = 1; i < aboveCannons.intValue; i++)
                        {
                            for (int i2 = 0; i2 < levels; i2++)
                            {
                                fullFile += "\t\tpublic void Cannon_" + i + "_" + i2 + "() { _enemyLogic._hit(" + i + "," + i2 + "); }\n";
                            }
                        }
                    }

                    if (swadgeShips.arraySize > 0)
                    {
                        for (int i = aboveEnemyTargets.intValue; i < aboveSwadgeShips.intValue; i++)
                        {
                            fullFile += "\t\tpublic void Swadge_" + i + "() { _enemyLogic._hit(" + i + "); }\n";
                        }
                    }

                    //Suffix goes here.
                    fullFile += "\t}\n" +
                        "}";


                    try
                    {
                        System.IO.File.WriteAllText(path, fullFile);
                    }
                    catch
                    {
                        Debug.LogError("Unable to write to path: " + path + ". Please create the folders and the U# file there first.");
                    }
                }
                catch
                {
                    Debug.LogError("There is no file at path: " + path + ". Please create the folders and the U# file there first.");
                }

                AssetDatabase.Refresh();
            }

            base.OnInspectorGUI();
        }
    }
}